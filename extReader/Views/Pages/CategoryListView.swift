//
//  CategoryListView.swift
//  extReader
//
//  Created by Renato Dias on 07/09/25.
//
import SwiftUI

struct CategoryListView: View {
    let category: String
    let expenses: [DetailedExpense]
    let total: Double
    
    var body: some View {
        HStack{
            VStack(alignment: .leading, spacing: 2) {
                Text("Total")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("R$ \(total, specifier: "%.2f")")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("\(expenses.count) \(expenses.count == 1 ? "despesa" : "despesas")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.bottom, 4)
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
            ScrollView{
                ForEach(expenses) { expense in
                    NavigationLink (destination:ExpenseDetailView(expense: expense))
                    {
                        VStack{
                            ExpenseListItemView(expense: expense)
                            Divider()
                        }
                    }
                }
            .navigationTitle(category)
            }
    }
}

#Preview {
    let mocks: [DetailedExpense] = [.mock, .mock]
    CategoryListView(category: "Outros", expenses: mocks, total: 100.00)
}
