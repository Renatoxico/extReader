//
//  CategoryChartView.swift
//  extReader
//
//  Created by Renato Dias on 07/09/25.
//

import SwiftUI
import Charts


struct CategoryChartView: View {
    let report: ExpenseResponse

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        let categories = report.ExpensesByCategory.sorted(by: { $0.value > $1.value })
        let totalExpenses = report.AllExpenses.reduce(0) { $0 + $1.value }
        VStack(spacing: 16) {
            // Header (outside card)
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.pie.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Despesas por Categoria")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                }
                Text("Resumo das categorias neste período")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)

            // Donut Chart
            Chart(categories, id: \.category) { item in
                let pct = item.value / totalExpenses * 100
                SectorMark(
                    angle: .value("Total", item.value),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .annotation(position: .overlay) {
                    if pct > 2 {
                        Text("\(String(format: "%.1f", pct))%")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.black)
                    }
                }
                .foregroundStyle(Color.forCategory(item.category))
                .cornerRadius(5)
            }
            .frame(height: 350)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let anchor = chartProxy.plotFrame {
                        let frame = geometry[anchor]
                        NavigationLink {
                            CategoryListView(
                                category: "Todas Despesas",
                                expenses: report.AllExpenses,
                                total: totalExpenses
                            )
                        } label: {
                            VStack(spacing: 4) {
                                Text("Total")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("R$ \(String(format: "%.2f", totalExpenses))")
                                    .font(.title3.weight(.semibold))
                                    .foregroundColor(.green)
                                Text("Ver Tudo →")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 150, height: 150)
                            .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }

            // Legend
            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(categories, id: \.category) { item in
                    let categoryExpenses = report.AllExpenses.filter { $0.category == item.category }
                    let totalByCategory = report.ExpensesByCategory.first(where: { $0.category == item.category })?.value ?? 0.0
                    NavigationLink {
                        CategoryListView(category: item.category, expenses: categoryExpenses, total: totalByCategory)
                    } label: {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.forCategory(item.category).opacity(0.2))
                                    .frame(width: 30, height: 30)
                                Image(systemName: String.iconName(forCategory: item.category))
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.forCategory(item.category))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.category)
                                    .font(.footnote.weight(.medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Text("R$ \(String(format: "%.2f", item.value))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.quaternarySystemFill))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal)
        .padding(.top)
        .padding(.bottom)
    }

}

#Preview {
    let mock = Bundle.main.decode(ExpenseResponse.self, from: "FakeReport.json")
    NavigationStack {
        CategoryChartView(report: mock)
    }
}
