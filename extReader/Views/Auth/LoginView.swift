//
//  LoginView.swift
//  extReader
//
//  Created by Renato Dias on 26/03/26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthService

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
                            .frame(maxWidth: 240)
                            .accessibilityLabel("Somai")

                        Text("Analise seus extratos bancários")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 48)

                    VStack(spacing: 16) {
                        if let error = auth.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Button {
                            Task { await auth.signInWithGoogle() }
                        } label: {
                            HStack(spacing: 10) {
                                if auth.isLoading {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Image(systemName: "globe")
                                        .font(.headline)
                                    Text("Entrar com Google")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                        }
                        .disabled(auth.isLoading)

                        consentLine
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .tint(.green)
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }
        }
    }

    private var consentLine: Text {
        var intro = AttributedString("Ao entrar, você concorda com os ")
        intro.foregroundColor = Color.secondary

        var terms = AttributedString("Termos de Uso")
        terms.link = AppConfig.termsOfUseURL
        terms.foregroundColor = Color.green
        terms.underlineStyle = .single

        var middle = AttributedString(" e a ")
        middle.foregroundColor = Color.secondary

        var privacy = AttributedString("Política de Privacidade")
        privacy.link = AppConfig.privacyPolicyURL
        privacy.foregroundColor = Color.green
        privacy.underlineStyle = .single

        var ending = AttributedString(".")
        ending.foregroundColor = Color.secondary

        return Text(intro + terms + middle + privacy + ending)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService.shared)
        .environment(\.colorScheme, .dark)
}
