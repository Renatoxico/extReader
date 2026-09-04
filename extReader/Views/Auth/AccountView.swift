//
//  AccountView.swift
//  extReader
//
//  Created by Renato Dias on 26/03/26.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        ZStack {
            BackgroundView()

            VStack(spacing: 24) {
                userHeader
                    .padding(.top, 32)

                Button(role: .destructive) {
                    Task { await auth.signOut() }
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sair")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
        }
        .navigationTitle("Conta")
        .navigationBarTitleDisplayMode(.inline)
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
