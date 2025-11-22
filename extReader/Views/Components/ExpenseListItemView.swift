//
//  ExpenseItemView.swift
//  extReader
//
//  Created by Renato Dias on 25/06/25.
//

import SwiftUI

struct ExpenseListItemView: View {
    let expense: DetailedExpense
    
    var body: some View {
        let iconName: String = .iconName(forCategory:expense.category ?? "Outros / Transferências")
        let catColor: Color = Color.forCategory(expense.category ?? "Outros / Transferências")
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(catColor)
                .font(.title2)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(catColor.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.expenseName)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                HStack {
                    Text("R$ \(expense.value, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    Spacer()
                    Text(expense.date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        //.background(Color(.systemBackground))
        //.overlay(
        //    Divider()
        //        .offset(y: 20),
        //    alignment: .bottom
        //)
    }

}

#Preview {
    ExpenseListItemView(expense: .mock)
}
