//
//  ExpensesView.swift
//  extReader
//
//  Created by Renato Dias on 28/10/25.
//

import SwiftUI

struct ExpensesView: View {
    @State var groupedList: [GroupedExpense]
    @State var allExpenses: [DetailedExpense]
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 5) {
                Text("Todas Despesas Agrupadas")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                    .padding(.horizontal, 4)
                    .padding(.bottom)
                
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
                            GroupedExpenseListItemView(expense: expense)
                                .padding()
                        }
                        .foregroundColor(.primary)
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.bottom)
                }
            }
            .padding(.top)
        }
        .padding(.horizontal,8)
    }
}
