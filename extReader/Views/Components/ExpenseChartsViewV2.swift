//
//  ExpenseChartsViewV2.swift
//  extReader
//
//  Created by Renato Dias on 28/11/25.
//

import SwiftUI
import DGCharts

struct ExpenseChartsViewV2: View {
    let report: ExpenseResponse
    var body: some View {
        let categories = report.ExpensesByCategory.sorted(by: { $0.value > $1.value })
        let entries = categories.map { PieChartDataEntry(value: Double($0.value), label: $0.category) }
        
        ChartView(entries: entries)
            
    }
}
