//
//  LoginView.swift
//  extReader
//
//  Created by Renato Dias on 26/03/26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView {
                VStack(spacing: 32) {
                    // Logo
                    VStack(spacing: 8) {
                        Image("logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 140, height: 140)

                        Text("extReader")
                            .font(.title.bold())
                            .foregroundColor(.white)

                        Text("Analise seus extratos bancários")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 48)

                    // Form
                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)

                            SecureField("Senha", text: $password)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                        }

                        if let error = auth.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Primary action button
                        Button {
                            Task {
                                if isSignUp {
                                    await auth.signUp(email: email, password: password)
                                } else {
                                    await auth.signIn(email: email, password: password)
                                }
                            }
                        } label: {
                            HStack {
                                if auth.isLoading {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Text(isSignUp ? "Criar conta" : "Entrar")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                        }
                        .disabled(auth.isLoading || email.isEmpty || password.isEmpty)

                        // Divider
                        HStack {
                            Rectangle().fill(Color(.separator)).frame(height: 1)
                            Text("ou").font(.caption).foregroundColor(.secondary).padding(.horizontal, 8)
                            Rectangle().fill(Color(.separator)).frame(height: 1)
                        }

                        // Google OAuth
                        Button {
                            Task { await auth.signInWithGoogle() }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "globe")
                                    .font(.headline)
                                Text("Continuar com Google")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                        }
                        .disabled(auth.isLoading)
                    }
                    .padding(.horizontal, 24)

                    // Toggle sign in / sign up
                    Button {
                        isSignUp.toggle()
                        auth.errorMessage = nil
                    } label: {
                        Text(isSignUp ? "Já tem conta? **Entrar**" : "Não tem conta? **Criar conta**")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService.shared)
        .environment(\.colorScheme, .dark)
}
