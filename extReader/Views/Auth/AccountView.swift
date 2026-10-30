//
//  AccountView.swift
//  extReader
//
//  Created by Renato Dias on 26/03/26.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var auth: AuthService
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView {
                VStack(spacing: 24) {
                    userHeader
                        .padding(.top, 32)

                    VStack(spacing: 12) {
                        accountButton(
                            title: "Sair",
                            systemImage: "rectangle.portrait.and.arrow.right"
                        ) {
                            Task { await auth.signOut() }
                        }
                        .disabled(auth.isDeletingAccount || auth.isLoading)

                        accountButton(
                            title: auth.isDeletingAccount ? "Excluindo..." : "Excluir conta",
                            systemImage: "trash",
                            isLoading: auth.isDeletingAccount
                        ) {
                            showDeleteConfirmation = true
                        }
                        .disabled(auth.isDeletingAccount || auth.isLoading)

                        if auth.deletionRequiresRecentSignIn {
                            Button {
                                Task { await auth.reauthenticateForAccountDeletion() }
                            } label: {
                                HStack(spacing: 8) {
                                    if auth.isLoading {
                                        ProgressView()
                                            .tint(.green)
                                    }
                                    Text("Confirmar identidade")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .disabled(auth.isDeletingAccount || auth.isLoading)
                        }

                        if let notice = auth.accountDeletionNotice {
                            Text(notice)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                        if let error = auth.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }

                    legalSection

                    Spacer(minLength: 24)
                }
            }
        }
        .navigationTitle("Conta")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Excluir conta?", isPresented: $showDeleteConfirmation) {
            Button("Excluir conta", role: .destructive) {
                Task { await auth.deleteAccount() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Sua conta, seus extratos e demais dados serão apagados de forma permanente. Esta ação não pode ser desfeita.")
        }
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Privacidade")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 28)

            VStack(spacing: 12) {
                legalLink(
                    title: "Política de Privacidade",
                    systemImage: "hand.raised",
                    url: AppConfig.privacyPolicyURL
                )
                legalLink(
                    title: "Termos de Uso",
                    systemImage: "doc.text",
                    url: AppConfig.termsOfUseURL
                )
            }
        }
    }

    private func accountButton(
        title: String,
        systemImage: String,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: .destructive, action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.red)
                } else {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .foregroundColor(.red)
            .cornerRadius(12)
            .padding(.horizontal, 24)
        }
    }

    private func legalLink(title: String, systemImage: String, url: URL) -> some View {
        Link(destination: url) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var userHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 80, height: 80)

                if let picture = auth.user?.picture,
                   let url = URL(string: picture) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.green)
                }
            }

            VStack(spacing: 4) {
                Text(auth.user?.name ?? "Conta")
                    .font(.headline)
                    .foregroundColor(.white)

                if let email = auth.user?.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AccountView()
            .environmentObject(AuthService.shared)
            .environment(\.colorScheme, .dark)
    }
}
