//
//  AuthService.swift
//  extReader
//
//  Created by Renato Dias on 26/03/26.
//

import Foundation
import Supabase

@MainActor
class AuthService: ObservableObject {

    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var isPremium: Bool? = nil   // nil = not yet checked
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    let client = SupabaseClient(
        supabaseURL: URL(string: SupabaseConfig.url)!,
        supabaseKey: SupabaseConfig.anonKey
    )

    private init() {
        Task { await startAuthListener() }
    }

    // MARK: - Auth State Listener

    private func startAuthListener() async {
        for await (event, session) in await client.auth.authStateChanges {
            switch event {
            case .initialSession:
                isAuthenticated = session != nil
                if session != nil { await checkPremiumStatus() }
            case .signedIn:
                isAuthenticated = true
                await checkPremiumStatus()
            case .signedOut, .userDeleted:
                isAuthenticated = false
                isPremium = nil
            case .tokenRefreshed:
                break
            default:
                break
            }
        }
    }

    // MARK: - Auth Actions

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await client.auth.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await client.auth.signUp(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        do {
            try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "extreader://auth-callback")
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Passes an incoming deep-link URL to the Supabase SDK (OAuth callback).
    func handleURL(_ url: URL) {
        Task { await client.handle(url) }
    }

    // MARK: - Premium Status

    func checkPremiumStatus() async {
        guard let token = try? await client.auth.session.accessToken else {
            isPremium = false
            return
        }
        do {
            guard let statusURL = URL(string: "https://api.renatoxico.net/api/user/status") else {
                isPremium = false
                return
            }
            var request = URLRequest(url: statusURL)
            request.timeoutInterval = 30
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                isPremium = nil
                return
            }
            struct StatusResponse: Decodable { let isPremium: Bool }
            isPremium = try JSONDecoder().decode(StatusResponse.self, from: data).isPremium
        } catch {
            isPremium = false
        }
    }

    // MARK: - Token Access (for ExpenseService)

    func accessToken() async throws -> String {
        try await client.auth.session.accessToken
    }
}
