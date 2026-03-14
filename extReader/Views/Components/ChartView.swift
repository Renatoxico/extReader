//
//  ChartView.swift
//  extReader
//
//  Created by Renato Dias on 28/11/25.
//

import SwiftUI
import DGCharts

struct ChartView: UIViewRepresentable {
    
    let entries: [PieChartDataEntry]

    func makeUIView(context: Context) -> PieChartView {
        let chart = PieChartView()
        chart.delegate = context.coordinator
        
        chart.usePercentValuesEnabled = true
        chart.drawHoleEnabled = true
        chart.holeRadiusPercent = 0.55
        chart.transparentCircleRadiusPercent = 0.60
        chart.transparentCircleColor = UIColor.black.withAlphaComponent(0.05)

        chart.holeColor = .clear
        chart.backgroundColor = .clear
        
        chart.rotationEnabled = false
        chart.highlightPerTapEnabled = true
        
        chart.centerText = "Tap a slice"
        chart.centerTextRadiusPercent = 1.0
        
        chart.legend.enabled = false
        chart.drawEntryLabelsEnabled = false
        
        return chart
    }
    
    func updateUIView(_ uiView: PieChartView, context: Context) {
        let set = PieChartDataSet(entries: entries)
        set.colors = entries.map { UIColor.forCategory($0.label ?? "") }

        // Styling
        set.sliceSpace = 3
        set.selectionShift = 12
        set.drawValuesEnabled = true
        set.valueTextColor = UIColor.label.withAlphaComponent(0.7)
        set.valueFont = .systemFont(ofSize: 12, weight: .semibold)
        set.valueFormatter = NoDecimalPercentFormatter()

        let data = PieChartData(dataSet: set)
        uiView.data = data
        
        // Animate chart load
        uiView.animate(xAxisDuration: 0.3, yAxisDuration: 0.6, easingOption: .easeOutBack)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ChartViewDelegate {
        var parent: ChartView
        
        init(_ parent: ChartView) {
            self.parent = parent
        }
        
        // When slice is tapped
        func pieChartView(_ chartView: PieChartView,
                          didSelectEntry entry: ChartDataEntry,
                          highlight: Highlight) {

            let name = entry.description
            let percent = String(format: "%.0f%%", entry.y)

            // Build styled center text
            let text = NSMutableAttributedString()
            
            text.append(NSAttributedString(
                string: "\(name)\n",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                    .foregroundColor: UIColor.label
                ]
            ))

            text.append(NSAttributedString(
                string: percent,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                    .foregroundColor: UIColor.systemBlue
                ]
            ))

            chartView.centerAttributedText = text
        }
        
        func chartValueNothingSelected(_ chartView: ChartViewBase) {
            chartView.noDataText = "Tap a slice"
        }
    }
    
    class NoDecimalPercentFormatter: ValueFormatter {
        func stringForValue(_ value: Double,
                                     entry: ChartDataEntry,
                                     dataSetIndex: Int,
                                     viewPortHandler: ViewPortHandler?) -> String {
            return String(format: "%.0f%%", value)
        }
    }
}


#Preview {
    let mock = Bundle.main.decode(ExpenseResponse.self, from: "FakeReport.json")
    ExpenseChartsViewV2(report: mock)
}
