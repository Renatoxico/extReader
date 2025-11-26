//
//  GroupedExpenseCard.swift
//  extReader
//
//  Created by Renato Dias on 26/11/25.
//

import SwiftUI

struct GroupedExpenseCard: View {
    let expense: GroupedExpense

    var body: some View {
        let iconName = String.iconName(forCategory: expense.category)
        let catColor = Color.forCategory(expense.category)

        HStack(spacing: 16) {

            RoundedRectangle(cornerRadius: 10)
                .fill(catColor.opacity(0.20))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: iconName)
                        .font(.title3.weight(.medium))
                        .foregroundColor(catColor)
                )

            VStack(alignment: .leading, spacing: 6) {

                Text(expense.expenseName)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Text("R$\(expense.total, specifier: "%.2f")")
                        .foregroundColor(.white.opacity(0.9))

                    Text("\(expense.instances)x")
                        .foregroundColor(.white.opacity(0.5))
                }
                .font(.subheadline)
            }

            Spacer()
        }
    }
}
