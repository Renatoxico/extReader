//
//  ExpenseDashboardView.swift
//  extReader
//
//  Created by Renato Dias on 22/11/25.
//

import SwiftUI

struct ExpenseDashboardView: View {
    let report: ExpenseResponse
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        let biggestExpense = report.BiggestSingularExpense
        let busyDay = report.NotableDays.sorted{$0.transactions > $1.transactions}.first!
        let expensiveDay = report.NotableDays.sorted{$0.total > $1.total}.first!
        let commonExpense = report.SmartGroupExpenselist.sorted{$0.instances > $1.instances}.first!
        let topExpenses = Array (report.SmartGroupExpenselist.sorted{$0.total > $1.total}.prefix(3))
      
        let comprasRecorrentes = report.AllExpenses.filter { $0.expenseName == commonExpense.expenseName }
        let busyDayExpenses = report.AllExpenses.filter { $0.date == busyDay.date }
        let expensiveDayExpenses = report.AllExpenses.filter { $0.date == expensiveDay.date }
        
        VStack(alignment: .leading, spacing: 10) {
            
            VStack(alignment: .leading) {
                Text("Destaques do Extrato")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            LazyVGrid(columns: columns, spacing: 16) {
                // 1. Biggest Singular Expense -> Opens Detail
                NavigationLink(destination: ExpenseDetailView(expense: biggestExpense)) {
                    StatCard(
                        title: "Maior Compra",
                        mainValue: "R$" + biggestExpense.value.description,
                        subValue: biggestExpense.expenseName,
                        icon: "crown.fill",
                        accentColor: .orange
                    )
                }
                // 2. Compra Mais Recorrente
                NavigationLink(destination: CategoryListView(category: "Compra Mais Recorrente", expenses: comprasRecorrentes, total: commonExpense.total)) {
                    StatCard(
                        title: "Compra Mais Recorrente",
                        mainValue: commonExpense.expenseName,
                        subValue: commonExpense.instances.description + "x",
                        icon: "arrow.triangle.2.circlepath",
                        accentColor: .blue
                    )
                }
                // 3. Dia Mais Movimentado
                NavigationLink(destination: CategoryListView(category: "Dia mais Movimentado", expenses: busyDayExpenses, total: busyDay.total)) {
                    StatCard(
                        title: "Dia Mais Movimentado",
                        mainValue: busyDay.date,
                        subValue: busyDay.transactions.description + " Transações",
                        icon: "calendar.badge.clock",
                        accentColor: .purple
                    )
                }
                // 4. Dia Mais Caro
                NavigationLink(destination: CategoryListView(category: "Dia mais Caro", expenses: expensiveDayExpenses, total: expensiveDay.total)) {
                    StatCard(
                        title: "Dia Mais Caro",
                        mainValue: expensiveDay.date,
                        subValue: "R$" + expensiveDay.total.description,
                        icon: "chart.bar.fill",
                        accentColor: .pink
                    )
                }
            }
            //.padding(.horizontal)
            TopExpensesView(groupedList: topExpenses, allExpenses: report.AllExpenses)
        }
    }
}

