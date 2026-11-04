import Foundation
func require(_ condition: @autoclosure () -> Bool, _ message: String) { if !condition() { fatalError(message) } }
let url = URL(fileURLWithPath: CommandLine.arguments[1])
let response = try JSONDecoder().decode(ExpenseResponse.self, from: Data(contentsOf: url))
let rows = response.AllExpenses.enumerated().map { i, row in NightExpense(id: i, name: row.expenseName, date: NightDates.parse(row.date)!, value: row.value, category: (row.category?.isEmpty ?? true) ? "Outros / Transferências" : row.category!) }
let summaries = Dictionary(uniqueKeysWithValues: response.ExpensesByCategory.map { ($0.category, $0.value) })
let prepared = PreparedReport.prepare(expenses: rows, summaries: summaries)
require(rows.count == 144, "144 fixture rows")
require(abs(prepared.all.total - 14521.1) < 0.01, "whole-period total")
require(prepared.months.count == 3, "3 months")
require(prepared.all.visibleCategories.count == 6, "Top 5 + Outras")
require(prepared.all.visibleCategories.last!.members.count == 10, "10 smaller categories")
require(prepared.all.expensive!.total == prepared.all.days.map(\.total).max()!, "consistent expensive day")
require(Set(prepared.all.expenses.map(\.id)).count == 144, "stable unique IDs")
for month in prepared.months {
    let report = prepared.filtered[month]!
    require(report.expenses.allSatisfy { YearMonth($0.date) == month }, "filter")
    require(abs(report.total - report.expenses.reduce(0) { $0 + $1.value }) < 0.01, "filtered total")
    for cat in report.categories { require(cat.colorHex == prepared.all.categories.first { $0.name == cat.name }!.colorHex, "stable color") }
}
let september = prepared.filtered[YearMonth(NightDates.parse("01/09/2026")!)]!
require(abs(september.total - 5308.19) < 0.01, "September total")
require(september.calendars[0].delta != nil, "full month delta")
require(september.biggest?.name == "LATAM Airlines", "monthly largest")
require(prepared.all.automatic == .week, "automatic week")
require(prepared.all.weekCells.count == 14, "14 Sunday weeks")
require(abs(prepared.all.cumulative.last!.total - prepared.all.total) < 0.01, "cumulative")
let same = NightDates.parse("01/01/2026")!
let duplicate = PreparedReport.prepare(expenses: [NightExpense(id: 0, name: "Loja", date: same, value: 10, category: "Outros / Transferências"), NightExpense(id: 1, name: "Loja", date: same, value: 10, category: "Outros / Transferências")], summaries: [:])
require(duplicate.all.occurrence[0] == 1 && duplicate.all.occurrence[1] == 2, "duplicate occurrence IDs")
require(duplicate.all.calendars[0].partial, "partial month")
require(duplicate.all.calendars[0].delta == nil, "hide partial delta")
let empty = PreparedReport.prepare(expenses: [], summaries: [:])
require(empty.all.total == 0 && empty.all.days.isEmpty, "empty report")
print("PASS: fixture, sums, month filters, stable colors, top-N, highlights, weeks, cumulative, duplicates, partial and empty reports")
let sevenCategories = (0..<7).map { NightExpense(id: $0, name: "Loja \($0)", date: same, value: Double($0 + 1), category: "Categoria \($0)") }
let seven = PreparedReport.prepare(expenses: sevenCategories, summaries: [:])
require(seven.all.visibleCategories.count == 6 && seven.all.visibleCategories.last!.members.count == 2, "7 categories aggregate 2")
let six = PreparedReport.prepare(expenses: Array(sevenCategories.prefix(6)), summaries: [:])
require(six.all.visibleCategories.count == 6 && six.all.visibleCategories.allSatisfy { $0.members.isEmpty }, "6 categories stay separate")
let thousandRows = (0..<1000).map { index in NightExpense(id: index, name: "Loja \(index % 30)", date: NightDates.calendar.date(byAdding: .day, value: index / 2, to: same)!, value: Double(index % 100 + 1), category: "Categoria \(index % 15)") }
let large = PreparedReport.prepare(expenses: thousandRows, summaries: [:])
require(large.all.expenses.count == 1000 && large.all.automatic == .month, "1000-row multi-year report")
require(large.all.chartPoints.count <= 100, "bounded accumulated chart points")
require(large.all.weekFlatCells.count == large.all.weekCells.count * 7, "week grid layout")
require(large.all.occurrence.count == 1000, "all duplicate-safe occurrences")
require(large.all.days.allSatisfy { NightDates.calendar.component(.hour, from: $0.date) == 0 }, "timezone-safe days")
print("PASS: 6/7 category boundary, 1000 rows, multi-year aggregation, bounded accumulated series and week cells")
