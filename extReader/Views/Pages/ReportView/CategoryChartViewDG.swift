//
//  CategoryChartViewDG.swift
//  extReader
//
//  Created by Renato Dias on 01/04/26.
//

import SwiftUI
import DGCharts

// MARK: - Interactive Donut Chart (UIViewRepresentable)

struct InteractiveDonutChart: UIViewRepresentable {
    let categories: [TotalByCategory]
    let totalExpenses: Double
    @Binding var selectedCategory: TotalByCategory?

    func makeUIView(context: Context) -> PieChartView {
        let chart = PieChartView()
        chart.delegate = context.coordinator

        // Donut styling
        chart.drawHoleEnabled = true
        chart.holeRadiusPercent = 0.55
        chart.transparentCircleRadiusPercent = 0.60
        chart.transparentCircleColor = UIColor.black.withAlphaComponent(0.05)
        chart.holeColor = .clear
        chart.backgroundColor = .clear

        // Interactions
        chart.rotationEnabled = false
        chart.highlightPerTapEnabled = true

        // Show percent values on slices
        chart.usePercentValuesEnabled = true

        // Hide built-in legend & labels (we draw our own)
        chart.legend.enabled = false
        chart.drawEntryLabelsEnabled = false

        // Center text default
        chart.setCenterText(total: totalExpenses)

        return chart
    }

    func updateUIView(_ uiView: PieChartView, context: Context) {
        let entries = categories.map {
            PieChartDataEntry(value: $0.value, label: $0.category)
        }

        let set = PieChartDataSet(entries: entries)
        set.colors = categories.map { UIColor.forCategory($0.category) }

        // Slice styling
        set.sliceSpace = 5
        set.selectionShift = 10
        set.drawValuesEnabled = true
        set.valueTextColor = UIColor.label.withAlphaComponent(0.8)
        set.valueFont = .systemFont(ofSize: 11, weight: .semibold)
        set.valueFormatter = PercentFormatter()

        let data = PieChartData(dataSet: set)
        uiView.data = data
        uiView.animate(xAxisDuration: 0.4, yAxisDuration: 0.6, easingOption: .easeOutBack)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ChartViewDelegate {
        var parent: InteractiveDonutChart

        init(_ parent: InteractiveDonutChart) {
            self.parent = parent
        }

        func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
            guard let pieEntry = entry as? PieChartDataEntry,
                  let label = pieEntry.label else { return }

            let matched = parent.categories.first { $0.category == label }
            parent.selectedCategory = matched

            // Update center text with selection
            if let chart = chartView as? PieChartView, let cat = matched {
                let pct = cat.value / parent.totalExpenses * 100
                let text = NSMutableAttributedString()
                text.append(NSAttributedString(
                    string: "\(label)\n",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                        .foregroundColor: UIColor.label
                    ]
                ))
                text.append(NSAttributedString(
                    string: "R$ \(String(format: "%.2f", cat.value))\n",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 17, weight: .bold),
                        .foregroundColor: UIColor.forCategory(label)
                    ]
                ))
                text.append(NSAttributedString(
                    string: String(format: "%.1f%%", pct),
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                        .foregroundColor: UIColor.secondaryLabel
                    ]
                ))
                chart.centerAttributedText = text
            }
        }

        func chartValueNothingSelected(_ chartView: ChartViewBase) {
            parent.selectedCategory = nil
            if let chart = chartView as? PieChartView {
                chart.setCenterText(total: parent.totalExpenses)
            }
        }
    }

    class PercentFormatter: ValueFormatter {
        func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
            return value >= 3 ? String(format: "%.0f%%", value) : ""
        }
    }
}

// Helper to set the default center text
extension PieChartView {
    func setCenterText(total: Double) {
        let text = NSMutableAttributedString()
        text.append(NSAttributedString(
            string: "Total\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
        ))
        text.append(NSAttributedString(
            string: "R$ \(String(format: "%.2f", total))",
            attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .bold),
                .foregroundColor: UIColor.systemGreen
            ]
        ))
        self.centerAttributedText = text
    }
}

// MARK: - Full Page View

struct CategoryChartViewDG: View {
    let report: ExpenseResponse

    @State private var selectedCategory: TotalByCategory?

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        let categories = report.ExpensesByCategory.sorted(by: { $0.value > $1.value })
        let totalExpenses = report.AllExpenses.reduce(0) { $0 + $1.value }

        VStack(spacing: 16) {
            // Header
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

            // Interactive Donut Chart
            InteractiveDonutChart(
                categories: categories,
                totalExpenses: totalExpenses,
                selectedCategory: $selectedCategory
            )
            .frame(height: 350)

            // Legend
            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(categories, id: \.category) { item in
                    let categoryExpenses = report.AllExpenses.filter { $0.category == item.category }
                    let totalByCategory = report.ExpensesByCategory.first(where: { $0.category == item.category })?.value ?? 0.0
                    let isSelected = selectedCategory?.category == item.category
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
                                .fill(isSelected
                                      ? Color.forCategory(item.category).opacity(0.12)
                                      : Color(.quaternarySystemFill))
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

#if DEBUG
#Preview {
    NavigationStack {
        CategoryChartViewDG(report: .preview)
    }
}
#endif
