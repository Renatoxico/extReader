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
                // Avatar placeholder
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "person.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.green)
                }
                .padding(.top, 32)

                // Premium badge
                premiumBadge

                // Sign out
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
    private var premiumBadge: some View {
        switch auth.isPremium {
        case true:
            Label("Premium ativo", systemImage: "crown.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.yellow)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.15))
                .cornerRadius(20)
        case false:
            Label("Plano gratuito", systemImage: "person.crop.circle")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
        case nil:
            ProgressView()
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
