//
//  TopExpensesView.swift
//  extReader
//
//  Created by Renato Dias on 02/11/25.
//


import SwiftUI

struct TopExpensesView: View {
    let expenses: [DetailedExpense] // ExpenseItem has name and amount
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Maiores Despesas")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(expenses) { expense in
                    NavigationLink (destination:ExpenseDetailView(expense: expense))
                    {
                        VStack{
                            ExpenseListItemView(expense: expense)
                            Divider()
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
            )
            //.padding(.horizontal)
        }
    }
}
