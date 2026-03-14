//
//  TopExpensesView.swift
//  extReader
//
//  Created by Renato Dias on 02/11/25.
//

import SwiftUI

struct TopExpensesView: View {
    @State var groupedList: [GroupedExpense]
    @State var allExpenses: [DetailedExpense]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Maiores Despesas")
                .font(.title3.bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                ForEach(groupedList) { expense in
                    let expenses = allExpenses.filter { $0.expenseName == expense.expenseName }
                    
                    NavigationLink {
                        if expense.instances == 1 {
                            ExpenseDetailView(expense: expenses.first!)
                        } else {
                            CategoryListView(category: expense.expenseName, expenses: expenses, total: expense.total)
                        }
                    } label: {
                        GroupedExpenseCard(expense: expense)
                            .padding()
                    }
                    .foregroundColor(.primary)
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.bottom)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                    //.padding(.horizontal,8)
            )
        }
        .padding(.horizontal,8)
    }
}

#Preview {
    let mock = Bundle.main.decode(ExpenseResponse.self, from: "FakeReport.json")
    ExpenseDashboardView(report: mock)
}
