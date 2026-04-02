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

    private var busyDay: NotableDay? {
        report.NotableDays.sorted { $0.transactions > $1.transactions }.first
    }
    private var expensiveDay: NotableDay? {
        report.NotableDays.sorted { $0.total > $1.total }.first
    }
    private var commonExpense: GroupedExpense? {
        report.SmartGroupExpenselist.sorted { $0.instances > $1.instances }.first
    }

    var body: some View {
        guard let busyDay, let expensiveDay, let commonExpense,
              let biggestExpense = report.BiggestSingularExpense else {
            return AnyView(
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Dados insuficientes para exibir destaques")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        }
        let topExpenses = Array(report.SmartGroupExpenselist.sorted { $0.total > $1.total }.prefix(3))
        let comprasRecorrentes = report.AllExpenses.filter { $0.expenseName == commonExpense.expenseName }
        let busyDayExpenses = report.AllExpenses.filter { $0.date == busyDay.date }
        let expensiveDayExpenses = report.AllExpenses.filter { $0.date == expensiveDay.date }

        return AnyView(VStack(alignment: .leading, spacing: 20) {

            // Título reforçado
            Text("Destaques do Extrato")
                .font(.title3.bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 4)

            // Grid
            LazyVGrid(columns: columns, spacing: 20) {
                NavigationLink(destination: ExpenseDetailView(expense: biggestExpense)) {
                    StatCard(
                        title: "Maior Compra",
                        mainValue: "R$" + biggestExpense.value.description,
                        subValue: biggestExpense.expenseName,
                        icon: "crown.fill",
                        accentColor: .orange
                    )
                }
                NavigationLink(destination: CategoryListView(category: "Compra Mais Recorrente", expenses: comprasRecorrentes, total: commonExpense.total)) {
                    StatCard(
                        title: "Compra Mais Recorrente",
                        mainValue: commonExpense.expenseName,
                        subValue: commonExpense.instances.description + "x",
                        icon: "arrow.triangle.2.circlepath",
                        accentColor: .blue
                    )
                }
                NavigationLink(destination: CategoryListView(category: "Dia mais Movimentado", expenses: busyDayExpenses, total: busyDay.total)) {
                    StatCard(
                        title: "Dia Mais Movimentado",
                        mainValue: busyDay.date,
                        subValue: busyDay.transactions.description + " Transações",
                        icon: "calendar.badge.clock",
                        accentColor: .purple
                    )
                }
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
            .padding(.horizontal, 4)

            // Separador suave
            Divider()
                .padding(.horizontal, 4)
                .padding(.top, 4)

            // Top Expenses
            TopExpensesView(groupedList: topExpenses, allExpenses: report.AllExpenses)
                .padding(.top, 4)
        }
        .padding(.top, 24)
        .padding(.bottom, 20)
        .padding(.horizontal, 8)
        )
    }

}

#Preview {
    let mock = Bundle.main.decode(ExpenseResponse.self, from: "FakeReport.json")
    ExpenseDashboardView(report: mock)
}
