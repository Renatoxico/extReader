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
    @Published var isPremium: Bool? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var user: AuthenticatedUser? = nil

    private let apiBaseURL = URL(string: "https://api.renatoxico.net")!
    private var authStateHandle: AuthStateDidChangeListenerHandle?

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

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            _ = try await Auth.auth().signIn(with: credential)
            await self.establishBackendSession()
        }
    }

    func signOut() async {
        errorMessage = nil

        do {
            GIDSignIn.sharedInstance.signOut()
            try Auth.auth().signOut()
            clearSession()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func handleURL(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    private func runAuthAction(_ action: @escaping @MainActor () async throws -> Void) async {
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

    func checkPremiumStatus() async {
        await establishBackendSession()
    }

    private func establishBackendSession() async {
        do {
            user = try await fetchAuthenticatedUser()
            isAuthenticated = true
            isPremium = false
        } catch {
            clearSession()
            errorMessage = authErrorMessage(for: error)
        }
        isAuthReady = true
    }

    private func clearSession() {
        isAuthenticated = false
        user = nil
        isPremium = nil
    }

    func fetchAuthenticatedUser() async throws -> AuthenticatedUser {
        let token = try await accessToken()
        let url = apiBaseURL.appending(path: "/api/auth/me")

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

    // MARK: - Token Access (for ExpenseService)

    func accessToken() async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthServiceError.notAuthenticated
        }

        return try await withCheckedThrowingContinuation { continuation in
            currentUser.getIDToken { token, error in
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

    private func authErrorMessage(for error: Error) -> String {
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
        case .weakPassword:
            return "A senha precisa ser mais forte."
        case .networkError:
            return "Não foi possível conectar ao serviço de autenticação."
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
