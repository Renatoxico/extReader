//
//  ExpenseHighlightsView.swift
//  extReader
//
//  Created by Renato Dias on 03/11/25.
//


import SwiftUI
import Charts

struct ExpenseHighlightsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Destaques do Período")
                .font(.title3.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ExpenseHighlightCard(
                    title: "Dia Mais Caro",
                    subtitle: "R$ 1.240,00",
                    detail: "18 de julho de 2025",
                    icon: "creditcard.fill",
                    gradient: Gradient(colors: [.purple, .indigo])
                ) {
                    print("Tapped Dia Mais Caro")
                }
                
                ExpenseHighlightCard(
                    title: "Dia com Mais Despesas",
                    subtitle: "12 transações",
                    detail: "22 de julho de 2025",
                    icon: "chart.bar.fill",
                    gradient: Gradient(colors: [.blue, .teal])
                ) {
                    print("Tapped Dia com Mais Despesas")
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Reusable Card Component
struct ExpenseHighlightCard: View {
    let title: String
    let subtitle: String
    let detail: String
    let icon: String
    let gradient: Gradient
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(width: 50, height: 50)
                        .cornerRadius(12)
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.title2.bold())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Simple Tap Animation Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ExpenseHighlightsView()
        .preferredColorScheme(.light)
        .padding()
}
