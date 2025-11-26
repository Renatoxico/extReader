//
//  BiggestExpenseView.swift
//  extReader
//
//  Created by Renato Dias on 30/10/25.
//

import SwiftUI


struct BiggestExpenseView: View {
    let expense: DetailedExpense

    var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text("Maior Despesa")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                // Main card
                HStack(spacing: 16) {
                    // Icon / category circle
                    Circle()
                        .fill(Color.forCategory(expense.category ?? "Outros / Transferências"))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Image(systemName: .iconName(forCategory: expense.category ?? "Outros / Transferências"))
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(expense.expenseName)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(expense.category ?? "Outros / Transferências")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("R$ \(String(format: "%.2f", expense.value))")
                            .font(.title3.bold())
                            .foregroundColor(.green)
                        Text(expense.date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                )
            }
            //.padding(.horizontal)
            .padding(.top, 8)
    }
}
