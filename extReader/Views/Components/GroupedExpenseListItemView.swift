//
//  GroupedExpenseView.swift
//  extReader
//
//  Created by Renato Dias on 29/06/25.
//

import SwiftUI

struct GroupedExpenseListItemView: View {
    let expense: GroupedExpense
    
    var body: some View {
        let iconName: String = .iconName(forCategory:expense.category)
        let catColor: Color = Color.forCategory(expense.category)
        HStack {
            Image(systemName: iconName)
                .foregroundColor(catColor)
                .font(.title2)
                .background(
                    Circle()
                        .fill(catColor.opacity(0.15))
                        .scaleEffect(1.8)
                )
                .padding(.trailing, 6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(expense.expenseName)")
                    .font(.body)
                    .lineLimit(1)
                HStack{
                    Text("R$\(expense.total,specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.green)
                        .lineLimit(1)
                    Spacer()
                    
                }
                .padding(0.0)
                
            }
            Text("\(expense.instances)x")
                .font(.title2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .padding(.trailing, 5)
        }
    }
}

