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
        
        VStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("Despesas por Categoria")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text("Resumo das categorias neste período")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ZStack {
                VStack(spacing: 0) {
                    Chart(categories, id: \.category) { item in
                        SectorMark(
                            angle: .value("Total", item.value),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(Color.forCategory(item.category))
                        .cornerRadius(5)
                        .shadow(color: .white.opacity(0.08), radius: 4)
                    }
                    .padding(.bottom)
                    .frame(height: 320)
                    .chartBackground { chartProxy in
                        GeometryReader { geometry in
                            if let anchor = chartProxy.plotFrame {
                                let frame = geometry[anchor]
                                NavigationLink {
                                    CategoryListView(category: "Todas Despesas", expenses: report.AllExpenses, total: totalExpenses)
                                } label: {
                                    VStack(spacing: 4) {
                                        Text("Total")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("R$ \(String(format: "%.2f", totalExpenses))")
                                            .font(.title3.weight(.semibold))
                                            .foregroundColor(.green)
                                    }
                                    .frame(width: 120, height: 120)
                                    .contentShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .position(x: frame.midX, y: frame.midY)
                            }
                        }
                    }
                    
                    //Divider().padding(.horizontal, 24)
                    
                    // Legend
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                        ForEach(categories, id: \.category) { item in
                            NavigationLink {
                                let categoryExpenses = report.AllExpenses.filter { $0.category == item.category }
                                let totalByCategory = report.ExpensesByCategory.first(where: { $0.category == item.category })?.value ?? 0.00
                                CategoryListView(category: item.category, expenses: categoryExpenses, total: totalByCategory)
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.forCategory(item.category))
                                        .frame(width: 12, height: 12)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.category)
                                            .font(.footnote.weight(.medium))
                                            .foregroundColor(.primary)
                                        Text("R$ \(String(format: "%.2f", item.value))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    //.padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }
            }
            .padding(.horizontal)
        }
        .padding(.top)
    }
}

#Preview {
    let mock = Bundle.main.decode(ExpenseResponse.self, from: "FakeReport.json")
    CategoryChartView(report: mock)
}

