//
//  ExpenseDetailView.swift
//  extReader
//
//  Created by Renato Dias on 10/09/25.
//
import SwiftUI

struct ExpenseDetailView: View {
    let expense: DetailedExpense    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                let iconName: String = .iconName(forCategory:expense.category ?? "Outros / Transferências")
                let catColor: Color = Color.forCategory(expense.category ?? "Outros / Transferências")
                // Icon + Category
                Image(systemName: iconName)
                    .font(.system(size: 60))
                    .foregroundColor(catColor)
                    .padding(.top, 20)
                    .shadow(color: catColor.opacity(0.25), radius: 8, y: 3)
                
                VStack(alignment: .leading, spacing: 12) {
                    
                    // Expense Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nome da Despesa")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(expense.expenseName)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    // Category
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Categoria")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(expense.category ?? "Sem categoria")
                            .font(.body)
                    }
                    
                    Divider()
                    
                    // Value + Date
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Valor")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("R$ \(expense.value, specifier: "%.2f")")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(expense.date)
                                .font(.body)
                        }
                    }
                }
                .padding()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
            )
        }
        .padding()
        .navigationTitle("Detalhes")
        .navigationBarTitleDisplayMode(.inline)
    }

}

#Preview {
    ExpenseDetailView(expense: .mock)
}
