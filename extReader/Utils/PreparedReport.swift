import Foundation

// Presentation snapshots intentionally leave the production response/decoder unchanged.
struct NightExpense: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let date: Date
    let value: Double
    let category: String
}
struct YearMonth: Hashable, Comparable, Identifiable, Sendable {
    let year: Int
    let month: Int
    var id: String { "\(year)-\(month)" }
    init(_ date: Date) { year = NightDates.calendar.component(.year, from: date); month = NightDates.calendar.component(.month, from: date) }
    var date: Date { NightDates.calendar.date(from: DateComponents(year: year, month: month, day: 1))! }
    var end: Date { NightDates.calendar.date(byAdding: .day, value: -1, to: NightDates.calendar.date(byAdding: .month, value: 1, to: date)!)! }
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.date < rhs.date }
}
enum NightDates {
    static var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.locale = Locale(identifier: "pt_BR"); c.timeZone = TimeZone(secondsFromGMT: 0)!; c.firstWeekday = 1; return c }
    static func parse(_ raw: String) -> Date? {
        let f = DateFormatter(); f.locale = Locale(identifier: "pt_BR"); f.timeZone = calendar.timeZone; f.dateFormat = "dd/MM/yyyy"; return f.date(from: raw)
    }
    static func days(_ start: Date, _ end: Date) -> [Date] {
        guard start <= end else { return [] }
        let count = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return (0...count).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
}
struct NightDay: Identifiable, Sendable {
    var id: Date { date }
    let date: Date
    let expenses: [NightExpense]
    let total: Double
    var count: Int { expenses.count }
}
struct NightCategory: Identifiable, Sendable {
    var id: String { name }
    let name: String
    let total: Double
    let count: Int
    let colorHex: UInt
    var members: [NightCategory] = []
}
struct NightMerchant: Identifiable, Sendable {
    var id: String { name }
    let name: String
    let category: String
    let expenses: [NightExpense]
    let total: Double
    let interval: Int
    var count: Int { expenses.count }
}
enum NightGranularity: String, CaseIterable, Sendable {
    case day = "Dia", week = "Semana", month = "Mês"
    var component: Calendar.Component { switch self { case .day: .day; case .week: .weekOfYear; case .month: .month } }
}
struct NightBucket: Identifiable, Sendable {
    var id: Date { date }
    let date: Date
    let end: Date
    let total: Double
    let categories: [NightCategory]
}
struct NightPoint: Identifiable, Sendable {
    var id: Date { date }
    let date: Date
    let total: Double
    let spent: Bool
}
struct NightCalendarCell: Identifiable, Sendable {
    var id: Date { date }
    let date: Date
    let number: Int
    let day: NightDay?
    let inPeriod: Bool
    let heat: Int
}
struct NightMonth: Identifiable, Sendable {
    var id: YearMonth { month }
    let month: YearMonth
    let cells: [NightCalendarCell]
    let total: Double
    let count: Int
    let spendDays: Int
    let partial: Bool
    let delta: Double?
}
struct NightTimelineMonth: Identifiable, Sendable {
    var id: YearMonth { month }
    let month: YearMonth
    let days: [NightDay]
    let total: Double
    let count: Int
}
struct FilteredReport: Sendable {
    let expenses: [NightExpense]
    let days: [NightDay]
    let dayLookup: [Date: NightDay]
    let categories: [NightCategory]
    let visibleCategories: [NightCategory]
    let merchants: [NightMerchant]
    let merchantLookup: [String: NightMerchant]
    let categoryReports: [String: NightDetail]
    let total: Double
    let start: Date
    let end: Date
    let biggest: NightExpense?
    let expensive: NightDay?
    let busiest: NightDay?
    let frequent: NightMerchant?
    let occurrence: [Int: Int]
    let intervalDays: [Int: Int]
    let recurring: Set<String>
    let heatThresholds: [Double]
    let calendars: [NightMonth]
    let weekCells: [[NightCalendarCell]]
    let weekTotals: [Double]
    let buckets: [NightGranularity: [NightBucket]]
    let cumulative: [NightPoint]
    let halfDate: Date?
    let timeline: [NightTimelineMonth]
    let dayCategories: [Date: [NightCategory]]
    let bucketAverages: [NightGranularity: Double]
    let chartPoints: [NightPoint]
    let monthEndPoints: [NightPoint]
    let weekFlatCells: [NightCalendarCell]
    let maxWeekTotal: Double
    var average: Double { total / Double(max(1, days.count)) }
    var span: Int { NightDates.calendar.dateComponents([.day], from: start, to: end).day ?? 0 }
    var automatic: NightGranularity { span <= 31 ? .day : (span <= 120 ? .week : .month) }
    func heat(_ value: Double) -> Int { value <= 0 ? 0 : (heatThresholds.firstIndex(where: { value <= $0 }).map { $0 + 1 } ?? 4) }
}
struct NightDetail: Sendable {
    let expenses: [NightExpense]
    let days: [NightDay]
    let merchants: [NightMerchant]
    let total: Double
    let largest: Double
}
struct PreparedReport: Sendable {
    let all: FilteredReport
    let months: [YearMonth]
    let filtered: [YearMonth: FilteredReport]
    static func prepare(expenses: [NightExpense], summaries: [String: Double]) -> Self {
        let sorted = expenses.sorted { $0.date == $1.date ? $0.id < $1.id : $0.date < $1.date }
        let byMonth = Dictionary(grouping: sorted) { YearMonth($0.date) }
        let months = byMonth.keys.sorted()
        let ranking = summaries.isEmpty ? Dictionary(grouping: sorted, by: \.category).mapValues { $0.reduce(0) { $0 + $1.value } } : summaries
        let order = ranking.keys.sorted { ranking[$0, default: 0] == ranking[$1, default: 0] ? $0 < $1 : ranking[$0, default: 0] > ranking[$1, default: 0] }
        var colors: [String: UInt] = [:]
        for (index, name) in order.enumerated() {
            colors[name] = index < 5 ? [UInt(0x10B981), 0xE3B25B, 0x7FB2F0, 0xE07A5F, 0xB79CF0][index] : UInt(0xA1A1A6) - UInt(min(index - 5, 9)) * 0x090909
        }
        if order.count <= 6 {
            for name in order {
                if name.hasPrefix("Supermercado") { colors[name] = 0x10B981 }
                else if name.hasPrefix("Transporte") { colors[name] = 0xE3B25B }
                else if name.hasPrefix("Restaurante") { colors[name] = 0xE07A5F }
                else if name.hasPrefix("Outros") { colors[name] = 0x8E8E93 }
            }
        }
        let all = build(sorted, summaries: ranking, colors: colors)
        let monthTotals = byMonth.mapValues { $0.reduce(0) { $0 + $1.value } }
        var cache: [YearMonth: FilteredReport] = [:]
        for month in months { cache[month] = build(byMonth[month]!, summaries: [:], colors: colors, globalTotals: monthTotals, bounds: (all.start, all.end)) }
        return Self(all: all, months: months, filtered: cache)
    }
    private static func build(_ expenses: [NightExpense], summaries: [String: Double], colors: [String: UInt], globalTotals: [YearMonth: Double] = [:], bounds: (Date, Date)? = nil) -> FilteredReport {
        let cal = NightDates.calendar
        let start = expenses.first?.date ?? Date(timeIntervalSince1970: 0), end = expenses.last?.date ?? Date(timeIntervalSince1970: 0)
        let days = Dictionary(grouping: expenses, by: \.date).map { NightDay(date: $0.key, expenses: $0.value, total: $0.value.reduce(0) { $0 + $1.value }) }.sorted { $0.date < $1.date }
        let lookup = Dictionary(uniqueKeysWithValues: days.map { ($0.date, $0) })
        let byCat = Dictionary(grouping: expenses, by: \.category)
        let catTotals = summaries.isEmpty ? byCat.mapValues { $0.reduce(0) { $0 + $1.value } } : summaries
        var categories: [NightCategory] = []
        for (name, value) in catTotals {
            let count: Int = byCat[name]?.count ?? 0
            let hex: UInt = colors[name] ?? 0x8E8E93
            categories.append(NightCategory(name: name, total: value, count: count, colorHex: hex))
        }
        categories.sort { a, b in a.total == b.total ? a.name < b.name : a.total > b.total }
        let total = categories.reduce(0) { $0 + $1.total }
        var visible = categories
        if categories.count > 6 {
            let others = Array(categories.dropFirst(5))
            visible = Array(categories.prefix(5)) + [NightCategory(name: "Outras", total: others.reduce(0) { $0 + $1.total }, count: others.reduce(0) { $0 + $1.count }, colorHex: 0x4A4A4E, members: others)]
        }
        let merchants: [NightMerchant] = Dictionary(grouping: expenses, by: \.name).map { name, rows -> NightMerchant in
            let intervals = zip(rows, rows.dropFirst()).map { cal.dateComponents([.day], from: $0.date, to: $1.date).day ?? 0 }
            let merchantTotal: Double = rows.reduce(0.0) { $0 + $1.value }
            let interval: Int = intervals.isEmpty ? 0 : intervals.reduce(0, +) / intervals.count
            let category: String = rows.first?.category ?? "Outros / Transferências"
            return NightMerchant(name: name, category: category, expenses: rows, total: merchantTotal, interval: interval)
        }.sorted { $0.total == $1.total ? $0.name < $1.name : $0.total > $1.total }
        var occurrence: [Int: Int] = [:]
        for merchant in merchants { for (i, e) in merchant.expenses.enumerated() { occurrence[e.id] = i + 1 } }
        var intervalDays: [Int: Int] = [:]
        for merchant in merchants {
            for (previous, next) in zip(merchant.expenses, merchant.expenses.dropFirst()) {
                intervalDays[next.id] = cal.dateComponents([.day], from: previous.date, to: next.date).day ?? 0
            }
        }
        let recurring = Set(merchants.filter { $0.count > 1 }.map(\.name))
        let values = days.map(\.total).sorted()
        let thresholds = [0.35, 0.70, 0.92].map { values.isEmpty ? 0 : values[min(values.count - 1, Int(Double(values.count - 1) * $0))] }
        func heat(_ value: Double) -> Int { value <= 0 ? 0 : (thresholds.firstIndex { value <= $0 }.map { $0 + 1 } ?? 4) }
        let monthGroups = Dictionary(grouping: days) { YearMonth($0.date) }
        let months = monthGroups.keys.sorted()
        let calendars = months.map { month -> NightMonth in
            let leading = cal.component(.weekday, from: month.date) - 1
            let gridStart = cal.date(byAdding: .day, value: -leading, to: month.date)!
            let monthDays = monthGroups[month] ?? []
            let monthTotal = monthDays.reduce(0) { $0 + $1.total }
            let lower = bounds?.0 ?? start, upper = bounds?.1 ?? end
            let partial = lower > month.date || upper < month.end
            let previous = YearMonth(cal.date(byAdding: .month, value: -1, to: month.date)!)
            let previousTotal = globalTotals[previous] ?? monthGroups[previous]?.reduce(0) { $0 + $1.total }
            let prevPartial = lower > previous.date || upper < previous.end
            let cells = NightDates.days(gridStart, month.end).map { date in NightCalendarCell(date: date, number: cal.component(.day, from: date), day: lookup[date], inPeriod: date >= start && date <= end && YearMonth(date) == month, heat: heat(lookup[date]?.total ?? 0)) }
            return NightMonth(month: month, cells: cells, total: monthTotal, count: monthDays.reduce(0) { $0 + $1.count }, spendDays: monthDays.count, partial: partial, delta: !partial && !prevPartial && (previousTotal ?? 0) > 0 ? monthTotal / previousTotal! - 1 : nil)
        }
        let weekStart = cal.dateInterval(of: .weekOfYear, for: start)!.start
        let weekEnd = cal.dateInterval(of: .weekOfYear, for: end)!.end.addingTimeInterval(-86400)
        let gridDays = NightDates.days(weekStart, weekEnd)
        var weekCells: [[NightCalendarCell]] = []
        for offset in stride(from: 0, to: gridDays.count, by: 7) {
            weekCells.append(gridDays[offset..<min(offset + 7, gridDays.count)].map { NightCalendarCell(date: $0, number: cal.component(.day, from: $0), day: lookup[$0], inPeriod: $0 >= start && $0 <= end, heat: heat(lookup[$0]?.total ?? 0)) })
        }
        let weekTotals = weekCells.map { $0.reduce(0) { $0 + ($1.day?.total ?? 0) } }
        var buckets: [NightGranularity: [NightBucket]] = [:]
        let topNames = Set(visible.filter { $0.members.isEmpty }.map(\.name))
        for granularity in NightGranularity.allCases {
            let grouped = Dictionary(grouping: expenses) { cal.dateInterval(of: granularity.component, for: $0.date)!.start }
            var bucketDates: [Date] = []
            var bucketDate = cal.dateInterval(of: granularity.component, for: start)!.start
            while bucketDate <= end {
                bucketDates.append(bucketDate)
                bucketDate = cal.date(byAdding: granularity.component, value: 1, to: bucketDate)!
            }
            buckets[granularity] = bucketDates.map { date in
                let rows = grouped[date] ?? []
                let partGroups: [String: [NightExpense]] = Dictionary(grouping: rows) { topNames.contains($0.category) ? $0.category : "Outras" }
                let parts: [NightCategory] = partGroups.map { name, partRows -> NightCategory in
                    let value: Double = partRows.reduce(0.0) { $0 + $1.value }
                    let hex: UInt = name == "Outras" ? 0x4A4A4E : (colors[name] ?? 0x8E8E93)
                    return NightCategory(name: name, total: value, count: partRows.count, colorHex: hex)
                }.sorted { $0.name < $1.name }
                return NightBucket(date: date, end: cal.dateInterval(of: granularity.component, for: date)!.end.addingTimeInterval(-86400), total: rows.reduce(0) { $0 + $1.value }, categories: parts)
            }
        }
        var running = 0.0
        let cumulative = NightDates.days(start, end).map { date -> NightPoint in running += lookup[date]?.total ?? 0; return NightPoint(date: date, total: running, spent: lookup[date] != nil) }
        var details: [String: NightDetail] = [:]
        for cat in categories {
            let rows = byCat[cat.name] ?? []
            let catDays: [NightDay] = Dictionary(grouping: rows, by: \.date).map { date, dayRows -> NightDay in
                let value: Double = dayRows.reduce(0.0) { $0 + $1.value }
                return NightDay(date: date, expenses: dayRows, total: value)
            }.sorted { $0.date < $1.date }
            details[cat.name] = NightDetail(expenses: rows, days: catDays, merchants: merchants.filter { $0.expenses.contains { $0.category == cat.name } }, total: cat.total, largest: rows.map(\.value).max() ?? 0)
        }
        let timeline = months.map { m in NightTimelineMonth(month: m, days: monthGroups[m]!, total: monthGroups[m]!.reduce(0) { $0 + $1.total }, count: monthGroups[m]!.reduce(0) { $0 + $1.count }) }
        var dayCategories: [Date: [NightCategory]] = [:]
        for day in days {
            let grouped = Dictionary(grouping: day.expenses, by: \.category)
            dayCategories[day.date] = grouped.map { name, rows -> NightCategory in
                let value = rows.reduce(0.0) { $0 + $1.value }
                return NightCategory(name: name, total: value, count: rows.count, colorHex: colors[name] ?? 0x8E8E93)
            }.sorted { $0.total > $1.total }
        }
        let bucketAverages: [NightGranularity: Double] = Dictionary(uniqueKeysWithValues: buckets.map { granularity, items in
            let denominator = granularity == .day ? days.count : items.count
            return (granularity, items.reduce(0.0) { $0 + $1.total } / Double(max(1, denominator)))
        })
        let strideSize = max(1, Int(ceil(Double(cumulative.count) / 98)))
        var chartPoints = stride(from: 0, to: cumulative.count, by: strideSize).map { cumulative[$0] }
        if chartPoints.last?.date != cumulative.last?.date, let last = cumulative.last { chartPoints.append(last) }
        let monthEnds = calendars.compactMap { month in cumulative.last { YearMonth($0.date) == month.month } }
        return FilteredReport(expenses: expenses, days: days, dayLookup: lookup, categories: categories, visibleCategories: visible, merchants: merchants, merchantLookup: Dictionary(uniqueKeysWithValues: merchants.map { ($0.name, $0) }), categoryReports: details, total: total, start: start, end: end, biggest: expenses.max { $0.value < $1.value }, expensive: days.max { $0.total < $1.total }, busiest: days.max { $0.count == $1.count ? $0.total < $1.total : $0.count < $1.count }, frequent: merchants.filter { $0.count > 1 }.max { $0.count == $1.count ? $0.total < $1.total : $0.count < $1.count }, occurrence: occurrence, intervalDays: intervalDays, recurring: recurring, heatThresholds: thresholds, calendars: calendars, weekCells: weekCells, weekTotals: weekTotals, buckets: buckets, cumulative: cumulative, halfDate: cumulative.first { $0.total >= total / 2 }?.date, timeline: timeline, dayCategories: dayCategories, bucketAverages: bucketAverages, chartPoints: chartPoints, monthEndPoints: monthEnds, weekFlatCells: weekCells.flatMap { $0 }, maxWeekTotal: weekTotals.max() ?? 0)
    }
}
