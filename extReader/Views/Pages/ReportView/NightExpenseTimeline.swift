import SwiftUI

private struct TimelineSelection: Sendable {
    var months: [NightTimelineMonth] = []
    var recurring: [NightMerchant] = []
    var unique: [NightMerchant] = []
    var count = 0
    var total = 0.0
    static func build(data: FilteredReport, query: String, category: String?, recurringOnly: Bool, start: Date?, end: Date?, sort: NightSort) -> Self {
        let rows = data.expenses.filter { row in
            (start == nil || row.date >= start!) && (end == nil || row.date <= end!) &&
            (category == nil || row.category == category) && (!recurringOnly || data.recurring.contains(row.name)) &&
            (query.isEmpty || row.name.localizedCaseInsensitiveContains(query) || row.category.localizedCaseInsensitiveContains(query))
        }
        let ids = Set(rows.map(\.id))
        let days = data.days.compactMap { day -> NightDay? in
            let expenses = day.expenses.filter { ids.contains($0.id) }
            return expenses.isEmpty ? nil : NightDay(date: day.date, expenses: expenses, total: expenses.reduce(0) { $0 + $1.value })
        }
        let byMonth = Dictionary(grouping: days) { YearMonth($0.date) }
        let months = byMonth.keys.sorted().map { month in
            let monthDays = byMonth[month]!.sorted { sort == .newest ? $0.date > $1.date : $0.date < $1.date }
            return NightTimelineMonth(month: month, days: monthDays, total: monthDays.reduce(0) { $0 + $1.total }, count: monthDays.reduce(0) { $0 + $1.count })
        }
        let merchants = data.merchants.compactMap { merchant -> NightMerchant? in
            let expenses = merchant.expenses.filter { ids.contains($0.id) }
            return expenses.isEmpty ? nil : NightMerchant(name: merchant.name, category: merchant.category, expenses: expenses, total: expenses.reduce(0) { $0 + $1.value }, interval: merchant.interval)
        }.sorted { lhs, rhs in
            switch sort {
            case .name: return lhs.name < rhs.name
            case .value: return lhs.total > rhs.total
            case .frequency: return lhs.count == rhs.count ? lhs.total > rhs.total : lhs.count > rhs.count
            case .category: return lhs.category == rhs.category ? lhs.total > rhs.total : lhs.category < rhs.category
            default: return lhs.expenses.last!.date > rhs.expenses.last!.date
            }
        }
        return Self(months: sort == .newest ? months.reversed() : months, recurring: merchants.filter { data.recurring.contains($0.name) }, unique: merchants.filter { !data.recurring.contains($0.name) }, count: rows.count, total: rows.reduce(0) { $0 + $1.value })
    }
}
private enum NightSort: String, CaseIterable, Sendable {
    case oldest = "Data crescente", newest = "Data decrescente", value = "Valor", frequency = "Frequência", name = "Nome", category = "Categoria"
}
struct NightExpenseTimeline: View {
    let data: FilteredReport
    var rangeStart: Date?
    var rangeEnd: Date?
    @EnvironmentObject private var store: NightReportStore
    @State private var query = ""
    @State private var category: String?
    @State private var recurringOnly = false
    @State private var grouped = false
    @State private var sort = NightSort.oldest
    @State private var selection = TimelineSelection()
    @State private var expanded: Set<String> = []
    private var taskKey: String { "\(query)|\(category ?? "")|\(recurringOnly)|\(sort.rawValue)" }
    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12, pinnedViews: [.sectionHeaders]) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Despesas").font(.largeTitle.bold())
                                Text("\(selection.count) lançamentos · \(Noturno.money(selection.total))").font(.caption).foregroundStyle(Noturno.secondary)
                            }
                            Spacer()
                            Menu {
                                Picker("Ordenar", selection: $sort) { ForEach(NightSort.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                            } label: { Image(systemName: "arrow.up.arrow.down").frame(width: 36, height: 36).background(Noturno.surface2, in: Circle()) }.accessibilityLabel("Ordenar despesas")
                        }
                        if let start = rangeStart, let end = rangeEnd { Text("\(Noturno.date(start)) – \(Noturno.date(end))").font(.caption).foregroundStyle(Noturno.amber) }
                        Picker("Visualização", selection: $grouped) { Text("Por dia").tag(false); Text("Agrupadas").tag(true) }.pickerStyle(.segmented)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                NightChip(title: "Todas", selected: category == nil && !recurringOnly) { category = nil; recurringOnly = false }
                                NightChip(title: "↻ Recorrentes", selected: recurringOnly) { recurringOnly.toggle() }
                                ForEach(data.categories) { cat in NightChip(title: cat.name, selected: category == cat.name, category: cat.name) { category = category == cat.name ? nil : cat.name } }
                            }
                        }
                    }.padding(.bottom, 6)
                    if selection.count == 0 { ContentUnavailableView.search(text: query) }
                    if grouped {
                        merchantSection("RECORRENTES", selection.recurring)
                        merchantSection("ÚNICAS", selection.unique)
                    } else if data.calendars.count <= 1 {
                        ForEach(selection.months) { month in
                            ForEach(month.days) { day in
                                Section {
                                    dayRow(day, showsHeader: false).id(day.date)
                                } header: {
                                    dayHeader(day).padding(.vertical, 8).background(Color(hex: 0x080909).opacity(0.98))
                                }
                            }
                        }
                    } else {
                        ForEach(selection.months) { month in
                            Section {
                                ForEach(month.days) { day in dayRow(day).id(day.date) }
                            } header: {
                                HStack {
                                    Text(Noturno.date(month.month.date, "MMMM yyyy").capitalized).font(.subheadline.bold())
                                    Spacer()
                                    Text("\(Noturno.money(month.total)) · \(month.count)").font(.caption)
                                }.padding(.vertical, 12).background(Color(hex: 0x080909).opacity(0.98))
                                    .overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.07)).frame(height: 0.5) }
                            }
                        }
                    }
                }.padding(.horizontal, 16).padding(.bottom, 30)
            }.onChange(of: selection.count) { _, _ in
                if let focus = store.focusDay { reader.scrollTo(focus, anchor: .top); store.focusDay = nil }
            }
        }.background { NoturnoBackground(tint: Noturno.amber) }
            .searchable(text: $query, prompt: "Buscar despesas")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: taskKey) {
                do { try await Task.sleep(for: .milliseconds(200)) } catch { return }
                let query = query, category = category, recurring = recurringOnly, sort = sort
                let snapshot = await Task.detached { TimelineSelection.build(data: data, query: query, category: category, recurringOnly: recurring, start: rangeStart, end: rangeEnd, sort: sort) }.value
                guard !Task.isCancelled else { return }; selection = snapshot
            }
    }
    private func dayRow(_ day: NightDay, showsHeader: Bool = true) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 0) {
                Circle().fill(heatColor(data.heat(day.total))).frame(width: nodeSize(day), height: nodeSize(day)).shadow(color: data.heat(day.total) == 4 ? Noturno.amber.opacity(0.4) : .clear, radius: 6)
                Rectangle().fill(LinearGradient(colors: [Noturno.amber.opacity(0.5), .white.opacity(0.06)], startPoint: .top, endPoint: .bottom)).frame(width: 2)
            }.frame(width: 22)
            VStack(alignment: .leading, spacing: 8) {
                if showsHeader { dayHeader(day) }
                ForEach(day.expenses) { expense in
                    Button { store.push(data.recurring.contains(expense.name) ? .merchant(expense.name) : .expense(expense.id)) } label: { NightExpenseRow(expense: expense, data: data) }
                }
            }.padding(.bottom, 12)
        }.fixedSize(horizontal: false, vertical: true)
    }
    private func dayHeader(_ day: NightDay) -> some View {
        Button { store.openDay(day.date) } label: {
            HStack {
                Text(Noturno.date(day.date, "EEE · dd MMM").uppercased()).font(.caption.bold())
                if day.date == data.biggest?.date { Text("● maior compra").font(.system(size: 9, weight: .semibold)).foregroundStyle(Noturno.amber) }
                Spacer(); Text(Noturno.money(day.total)).font(.caption).foregroundStyle(Noturno.secondary)
            }.padding(.vertical, 4).contentShape(Rectangle())
        }
    }
    private func nodeSize(_ day: NightDay) -> CGFloat { 10 + 12 * sqrt(max(0, day.total) / max(data.expensive?.total ?? 1, 0.01)) }
    @ViewBuilder private func merchantSection(_ title: String, _ merchants: [NightMerchant]) -> some View {
        if !merchants.isEmpty {
            Text(title).font(.caption.bold()).foregroundStyle(Noturno.secondary)
            ForEach(merchants) { merchant in
                VStack(spacing: 8) {
                    HStack {
                        Button { store.push(.merchant(merchant.name)) } label: { NightMerchantRow(merchant: merchant, total: selection.total) }
                        if merchant.count > 1 { Button { withAnimation { if expanded.contains(merchant.name) { expanded.remove(merchant.name) } else { expanded.insert(merchant.name) } } } label: { Image(systemName: expanded.contains(merchant.name) ? "chevron.up" : "chevron.down").frame(width: 36, height: 44) }.accessibilityLabel("Mostrar compras de \(merchant.name)") }
                    }
                    if expanded.contains(merchant.name) {
                        ForEach(merchant.expenses) { expense in
                            Button { store.openDay(expense.date) } label: { HStack { Text(Noturno.date(expense.date)); Spacer(); Text(Noturno.money(expense.value)).moneyFont(15) }.font(.caption).padding(.vertical, 8) }
                        }
                    }
                }.nightCard()
            }
        }
    }
}
