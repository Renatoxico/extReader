//
//  AuthService.swift
//  extReader
//
//  Created by Renato Dias on 26/03/26.
//

import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn
import UIKit

struct AuthenticatedUser: Decodable {
    let localUserId: Int64
    let uid: String
    let email: String?
    let name: String?
    let picture: String?
    let emailVerified: Bool
}

@MainActor
class AuthService: ObservableObject {

    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var isAuthReady = false
    @Published var isLoading = false
    @Published var isDeletingAccount = false
    @Published var deletionRequiresRecentSignIn = false
    /// Shown after a failed deletion attempt. Never describes the account as deleted.
    @Published var accountDeletionNotice: String? = nil
    @Published var errorMessage: String? = nil
    @Published var user: AuthenticatedUser? = nil

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    /// Set once DELETE /v2/account succeeds, so an in-flight session refresh cannot sign the user back in.
    private var accountDeletionCompleted = false
    private var microsoftProvider: OAuthProvider?

    private init() {
        FirebaseConfiguration.configureIfNeeded()
        startAuthListener()
    }

    deinit {
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }

    // MARK: - Auth State Listener

    private func startAuthListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                guard let self else { return }

                if firebaseUser == nil {
                    self.clearSession()
                    self.isAuthReady = true
                    return
                }

                await self.establishBackendSession()
            }
        }
    }

    // MARK: - Auth Actions

    func signIn(email: String, password: String) async {
        await runAuthAction {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            await self.establishBackendSession()
        }
    }

    func signUp(email: String, password: String) async {
        await runAuthAction {
            _ = try await Auth.auth().createUser(withEmail: email, password: password)
            await self.establishBackendSession()
        }
    }

    func signInWithGoogle() async {
        await runAuthAction {
            let credential = try await self.googleCredential()
            _ = try await Auth.auth().signIn(with: credential)
            await self.establishBackendSession()
        }
    }

    // TODO: Sign in with Apple is not implemented. When it is added, keep the Apple
    // authorization code from the credential and revoke it in `revokeProviderTokensIfNeeded()`
    // before `DELETE /v2/account`. Apple requires that revocation on account deletion.
    func signInWithMicrosoft() async {
        await runAuthAction {
            let credential = try await self.microsoftCredential()
            _ = try await Auth.auth().signIn(with: credential)
            await self.establishBackendSession()
        }
    }

    func signOut() async {
        errorMessage = nil
        accountDeletionNotice = nil
        deletionRequiresRecentSignIn = false

        do {
            GIDSignIn.sharedInstance.signOut()
            try Auth.auth().signOut()
            clearSession()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAccount() async {
        guard !isDeletingAccount else { return }

        isDeletingAccount = true
        errorMessage = nil
        accountDeletionNotice = nil
        deletionRequiresRecentSignIn = false
        defer { isDeletingAccount = false }

        do {
            // Revocation runs first. If it throws, the account still exists and the user stays signed in.
            try await revokeProviderTokensIfNeeded()
            try await performAccountDeletionRequest()
            endSessionAfterAccountDeletion()
        } catch {
            deletionRequiresRecentSignIn = isRecentLoginFailure(error)
            accountDeletionNotice = nil
            errorMessage = accountDeletionMessage(for: error)
        }
    }

    /// Re-authenticates the current user without signing out.
    /// A failed or canceled confirmation leaves the account in place.
    func reauthenticateForAccountDeletion() async {
        guard !isLoading, !isDeletingAccount else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            guard let currentUser = Auth.auth().currentUser else {
                throw AuthServiceError.notAuthenticated
            }
            let providerIDs = Set(currentUser.providerData.map(\.providerID))
            let credential: AuthCredential
            if providerIDs.contains("google.com") {
                credential = try await googleCredential()
            } else if providerIDs.contains("microsoft.com") {
                credential = try await microsoftCredential()
            } else {
                // Password reauthentication needs a password supplied by the user.
                // There is no password confirmation flow in AccountView yet.
                throw AuthServiceError.unsupportedReauthentication
            }
            _ = try await currentUser.reauthenticate(with: credential)
            deletionRequiresRecentSignIn = false
            errorMessage = nil
            accountDeletionNotice = "Identidade confirmada. A conta ainda não foi excluída. Toque em Excluir conta para continuar."
        } catch {
            if isSignInCancellation(error) {
                return
            }
            deletionRequiresRecentSignIn = true
            accountDeletionNotice = nil
            errorMessage = "A conta não foi excluída. Não foi possível confirmar sua identidade. Tente novamente."
        }
    }

    func handleURL(_ url: URL) -> Bool {
        if Auth.auth().canHandle(url) {
            return true
        }
        return GIDSignIn.sharedInstance.handle(url)
    }

    private func runAuthAction(_ action: @escaping @MainActor () async throws -> Void) async {
        accountDeletionCompleted = false
        isLoading = true
        errorMessage = nil

        do {
            try await action()
        } catch {
            clearSession()
            errorMessage = authErrorMessage(for: error)
        }

        isLoading = false
        isAuthReady = true
    }

    // MARK: - Backend User

    private func establishBackendSession() async {
        do {
            let authenticatedUser = try await fetchAuthenticatedUser()
            guard !accountDeletionCompleted else {
                clearSession()
                isAuthReady = true
                return
            }
            user = authenticatedUser
            isAuthenticated = true
        } catch {
            clearSession()
            if !accountDeletionCompleted {
                errorMessage = authErrorMessage(for: error)
            }
        }
        isAuthReady = true
    }

    private func clearSession() {
        isAuthenticated = false
        user = nil
    }

    func fetchAuthenticatedUser() async throws -> AuthenticatedUser {
        let token = try await accessToken()
        let url = AppConfig.apiBaseURL
            .appending(path: "api")
            .appending(path: "auth")
            .appending(path: "me")

        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let serverError = try? JSONDecoder().decode(ServerErrorResponse.self, from: data),
               let message = serverError.message {
                throw AuthServiceError.serverError(message)
            }

            throw AuthServiceError.invalidResponse
        }

        return try JSONDecoder().decode(AuthenticatedUser.self, from: data)
    }

    /// Provider cleanup that must succeed before the account is deleted.
    /// Google Sign-In has no separate revocation step. Sign in with Apple is not implemented.
    ///
    /// TODO: When Sign in with Apple is added, revoke the stored Apple authorization code
    /// here — before `DELETE /v2/account` — with `Auth.auth().revokeToken(withAuthorizationCode:)`.
    /// If revocation fails, throw and do not sign the user out. The account still exists,
    /// and the UI must not look as if deletion succeeded.
    private func revokeProviderTokensIfNeeded() async throws {
        // Google Sign-In does not require a separate revocation call.
        //
        // TODO: Sign in with Apple is not implemented. When that provider is added,
        // keep the authorization code from the Apple credential and revoke it here,
        // before DELETE /v2/account:
        //
        //     try await Auth.auth().revokeToken(withAuthorizationCode: authorizationCode)
        //
        // If revocation fails, throw. Do not sign the user out — the account still exists,
        // and the UI must not look as if deletion succeeded.
    }

    /// Deletes the signed-in user's data and Firebase user via `DELETE /v2/account`.
    /// Uses the same bearer ID token as the other authenticated requests.
    private func performAccountDeletionRequest() async throws {
        let token = try await accessToken(forcingRefresh: true)
        let url = AppConfig.apiBaseURL
            .appending(path: "v2")
            .appending(path: "account")

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = 30
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw accountDeletionError(from: data, statusCode: httpResponse.statusCode)
        }
    }

    /// Local sign-out. Call only after `DELETE /v2/account` has succeeded.
    /// Logging out is how the UI shows that deletion worked, so failure paths must not call this.
    private func endSessionAfterAccountDeletion() {
        accountDeletionCompleted = true
        errorMessage = nil
        accountDeletionNotice = nil
        deletionRequiresRecentSignIn = false
        GIDSignIn.sharedInstance.signOut()

        do {
            try Auth.auth().signOut()
        } catch {
            // The account is already deleted on the server. Drop the local session anyway.
        }

        clearSession()
    }

    private func accountDeletionError(from data: Data, statusCode: Int) -> AuthServiceError {
        let serverError = try? JSONDecoder().decode(ServerErrorResponse.self, from: data)
        if isRecentLoginRequired(serverError, statusCode: statusCode) {
            return .requiresRecentLogin
        }

        if let message = serverError?.message, !message.isEmpty {
            return .serverError(message)
        }

        return .accountDeletionFailed
    }

    private func isRecentLoginRequired(_ serverError: ServerErrorResponse?, statusCode: Int) -> Bool {
        if statusCode == 401 {
            return true
        }

        let errorCode = serverError?.errorCode?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if let errorCode, Self.recentLoginErrorCodes.contains(errorCode) {
            return true
        }

        let blob = [serverError?.errorCode, serverError?.message, serverError?.details]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()

        return Self.recentLoginMarkers.contains { blob.contains($0) }
    }

    private func isRecentLoginFailure(_ error: Error) -> Bool {
        if let authError = error as? AuthServiceError {
            if case .requiresRecentLogin = authError {
                return true
            }
            return false
        }

        return isFirebaseRecentLoginError(error)
    }

    private func isFirebaseRecentLoginError(_ error: Error) -> Bool {
        func matches(_ nsError: NSError) -> Bool {
            nsError.domain == AuthErrorDomain
                && AuthErrorCode(rawValue: nsError.code) == .requiresRecentLogin
        }

        let nsError = error as NSError
        if matches(nsError) {
            return true
        }

        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError, matches(underlying) {
            return true
        }

        return false
    }

    private func accountDeletionMessage(for error: Error) -> String {
        if isRecentLoginFailure(error) {
            return AuthServiceError.requiresRecentLogin.localizedDescription
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .timedOut:
                return "A conta não foi excluída. Verifique sua internet e tente novamente."
            default:
                break
            }
        }

        if let authError = error as? AuthServiceError {
            switch authError {
            case .requiresRecentLogin, .accountDeletionFailed:
                return authError.localizedDescription
            case .serverError(let message):
                return "A conta não foi excluída. \(message)"
            default:
                return "A conta não foi excluída. \(authError.localizedDescription)"
            }
        }

        return AuthServiceError.accountDeletionFailed.localizedDescription
    }

    private func googleCredential() async throws -> AuthCredential {
        guard let clientID = FirebaseApp.app()?.options.clientID, !clientID.isEmpty else {
            throw AuthServiceError.missingGoogleClientID
        }

        guard let presentingViewController = UIApplication.shared.activeRootViewController else {
            throw AuthServiceError.missingPresentingViewController
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthServiceError.missingGoogleIDToken
        }

        return GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
    }

    private func microsoftCredential() async throws -> AuthCredential {
        let provider = OAuthProvider(providerID: "microsoft.com")
        microsoftProvider = provider
        defer { microsoftProvider = nil }

        provider.customParameters = ["prompt": "select_account"]
        provider.scopes = ["email"]
        return try await provider.credential(with: nil)
    }

    private func isSignInCancellation(_ error: Error) -> Bool {
        let nsError = error as NSError
        return (nsError.domain == kGIDSignInErrorDomain
            && nsError.code == GIDSignInError.Code.canceled.rawValue)
            || (nsError.domain == AuthErrorDomain
                && AuthErrorCode(rawValue: nsError.code) == .webContextCancelled)
    }

    private static let recentLoginErrorCodes: Set<String> = [
        "REQUIRES_RECENT_LOGIN",
        "AUTH_REQUIRES_RECENT_LOGIN",
        "RECENT_LOGIN_REQUIRED",
        "CREDENTIAL_TOO_OLD_LOGIN_AGAIN",
        "AUTH_TOKEN_INVALID",
        "AUTH_TOKEN_MISSING"
    ]

    private static let recentLoginMarkers = [
        "requires-recent-login",
        "requires_recent_login",
        "recent_login",
        "recent-login",
        "credential_too_old",
        "credential-too-old",
        "login_again"
    ]

    // MARK: - Token Access (for ExpenseService)

    func accessToken() async throws -> String {
        try await accessToken(forcingRefresh: false)
    }

    private func accessToken(forcingRefresh: Bool) async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthServiceError.notAuthenticated
        }

        return try await withCheckedThrowingContinuation { continuation in
            currentUser.getIDTokenForcingRefresh(forcingRefresh) { token, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let token, !token.isEmpty else {
                    continuation.resume(throwing: AuthServiceError.missingIDToken)
                    return
                }

                continuation.resume(returning: token)
            }
        }
    }

    private func authErrorMessage(for error: Error) -> String? {
        if let authError = error as? AuthServiceError {
            return authError.localizedDescription
        }

        let nsError = error as NSError
        switch AuthErrorCode(rawValue: nsError.code) {
        case .invalidEmail:
            return "Email inválido."
        case .wrongPassword, .invalidCredential:
            return "Email ou senha inválidos."
        case .emailAlreadyInUse:
            return "Este email já está em uso."
        case .accountExistsWithDifferentCredential:
            return "Este e-mail já está cadastrado com Google. Entre com Google."
        case .webContextCancelled:
            return nil
        case .weakPassword:
            return "A senha precisa ser mais forte."
        case .networkError:
            return "Não foi possível conectar ao serviço de autenticação."
        case .requiresRecentLogin:
            return "Por segurança, entre novamente para continuar."
        default:
            return error.localizedDescription
        }
    }
}

private enum AuthServiceError: LocalizedError {
    case invalidResponse
    case missingGoogleClientID
    case missingGoogleIDToken
    case missingIDToken
    case missingPresentingViewController
    case notAuthenticated
    case unsupportedReauthentication
    case requiresRecentLogin
    case accountDeletionFailed
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Resposta inválida do servidor."
        case .missingGoogleClientID:
            return "FirebaseClientID não está configurado."
        case .missingGoogleIDToken:
            return "O Google não retornou um token de autenticação."
        case .missingIDToken:
            return "O Firebase não retornou um token de autenticação."
        case .missingPresentingViewController:
            return "Não foi possível abrir o login do Google."
        case .notAuthenticated:
            return "Faça login para continuar."
        case .unsupportedReauthentication:
            return "Não foi possível confirmar sua identidade com este provedor."
        case .requiresRecentLogin:
            return "A conta não foi excluída. Por segurança, confirme sua identidade e tente outra vez."
        case .accountDeletionFailed:
            return "A conta não foi excluída. Tente novamente."
        case .serverError(let message):
            return message
        }
    }
}

private enum FirebaseConfiguration {
    static func configureIfNeeded() {
        guard FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()
    }
}

private extension UIApplication {
    var activeRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController?
            .topMostViewController
    }
}

private extension UIViewController {
    var topMostViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.topMostViewController
        }

        if let navigationController = self as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return visibleViewController.topMostViewController
        }

        if let tabBarController = self as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return selectedViewController.topMostViewController
        }

        return self
    }
}
