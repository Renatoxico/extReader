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
                NightTile(category: expense.category ?? "Outros / Transferências")
                    .padding(.top, 20)
                
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
                            Text(Noturno.money(expense.value))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Noturno.text)
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
