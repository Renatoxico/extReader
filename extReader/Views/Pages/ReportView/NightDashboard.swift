import SwiftUI

struct NightProportionBar: View {
    let categories: [NightCategory]
    let total: Double
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 3) {
                ForEach(categories) { category in
                    let fraction: Double = category.total / max(total, 0.01)
                    let available: CGFloat = max(0, geometry.size.width - CGFloat(max(0, categories.count - 1)) * 3)
                    Capsule().fill(Color.forCategory(category.name))
                        .frame(width: available * CGFloat(max(0, fraction)))
                        .accessibilityLabel("\(category.name), \(Int(fraction * 100)) por cento")
                }
            }
        }.frame(height: 8)
    }
}
struct NightDashboard: View {
    let data: FilteredReport
    @EnvironmentObject private var store: NightReportStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var heroVisible = true
    @State private var shownTotal = 0.0
    private var title: String {
        guard let month = store.month else { return "Total do período" }
        return "Total de \(Noturno.date(month.date, "MMMM"))\(data.calendars.first?.partial == true ? " (parcial)" : "")"
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RELATÓRIO").font(.caption.weight(.semibold)).tracking(0.6).foregroundStyle(Noturno.emerald)
                    Text("\(Noturno.date(data.start)) – \(Noturno.date(data.end, "dd MMM yyyy"))").font(.subheadline).foregroundStyle(Noturno.secondary)
                }
                if data.expenses.isEmpty {
                    ContentUnavailableView("Seu relatório está vazio", systemImage: "receipt", description: Text("Use + para adicionar uma despesa."))
                }
                monthSelector
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.caption).foregroundStyle(Noturno.secondary)
                    Text(Noturno.money(shownTotal)).moneyFont(46).contentTransition(.numericText())
                    if let delta = data.calendars.first?.delta, let month = store.month { deltaLabel(delta, month: month) }
                    Text("\(data.expenses.count) lançamentos · \(data.merchants.count) estabelecimentos · \(data.categories.count) categorias")
                        .font(.caption).foregroundStyle(Noturno.secondary)
                }.background { GeometryReader { proxy in Color.clear.preference(key: HeroPositionKey.self, value: proxy.frame(in: .named("reportScroll")).maxY) } }
                Button { store.push(.charts) } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        NightProportionBar(categories: data.visibleCategories, total: data.total)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                            ForEach(data.visibleCategories) { category in
                                HStack(spacing: 5) {
                                    NightTile(category: category.name)
                                    Text("\(category.name)\(category.members.isEmpty ? "" : " (\(category.members.count))") \(Int(category.total / max(data.total, 0.01) * 100))%")
                                        .font(.caption2).foregroundStyle(Noturno.secondary)
                                }
                            }
                        }
                    }.contentShape(Rectangle())
                }.accessibilityLabel("Para onde foi. Explorar categorias, dias e acumulado")
                if data.calendars.count > 1 && store.month == nil { monthlyComparison }
                NightCalendar(data: data)
                highlights
                HStack {
                    Text("Maiores despesas").font(.title3.bold())
                    Spacer()
                    Button("Ver todas") { store.push(.allExpenses(nil, nil)) }.font(.caption)
                }
                VStack(spacing: 0) {
                    ForEach(Array(data.merchants.prefix(3))) { merchant in
                        Button { store.push(.merchant(merchant.name)) } label: {
                            NightMerchantRow(merchant: merchant, total: data.total)
                        }
                    }
                }.nightCard()
            }.padding(16).padding(.bottom, 24)
        }.coordinateSpace(name: "reportScroll")
            .onPreferenceChange(HeroPositionKey.self) { heroVisible = $0 > 0 }
            .toolbar { ToolbarItem(placement: .principal) {
                if !heroVisible { Text("\(Noturno.money(data.total)) · \(Noturno.date(data.start)) – \(Noturno.date(data.end))").font(.caption.bold()).transition(.opacity) }
            } }
            .onChange(of: data.total) { _, value in shownTotal = value }
            .onAppear {
                if reduceMotion || data.expenses.count > 300 { shownTotal = data.total }
                else { withAnimation(.easeOut(duration: 0.6)) { shownTotal = data.total } }
            }
    }
    @ViewBuilder private var monthSelector: some View {
        if let prepared = store.prepared, prepared.months.count >= 2 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    NightChip(title: "Todos", selected: store.month == nil) { store.month = nil; store.feedback += 1 }
                    ForEach(prepared.months) { month in
                        NightChip(title: Noturno.date(month.date, month.year >= 2027 ? "MMM yy" : "MMM").capitalized, selected: store.month == month) { store.month = month; store.feedback += 1 }
                    }
                }
            }
        }
    }
    private var monthlyComparison: some View {
        NightMonthlyComparison(months: data.calendars) { month in
            store.month = month
            store.feedback += 1
        }
    }

    private var highlights: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(store.month.map { "Destaques de \(Noturno.date($0.date, "MMMM"))" } ?? "Destaques").font(.title3.bold())
            if let biggest = data.biggest {
                Button { store.push(.merchant(biggest.name)) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Maior compra", systemImage: "creditcard").font(.caption).foregroundStyle(Noturno.secondary)
                            Text(Noturno.money(biggest.value)).moneyFont(34)
                            Text("\(biggest.name) · \(Noturno.date(biggest.date))").font(.caption).foregroundStyle(Noturno.secondary)
                        }
                        Spacer()
                        ZStack {
                            Circle().stroke(Noturno.amber.opacity(0.12), lineWidth: 5)
                            Circle().trim(from: 0, to: min(1, biggest.value / max(data.total, 0.01))).stroke(Noturno.amber, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90))
                            Text("\(Int(biggest.value / max(data.total, 0.01) * 100))%").font(.caption.bold())
                        }.frame(width: 58, height: 58)
                    }.nightCard().background(RadialGradient(colors: [Noturno.amber.opacity(0.15), .clear], center: .topTrailing, startRadius: 0, endRadius: 250), in: RoundedRectangle(cornerRadius: 22))
                }
            }
            VStack(spacing: 16) {
                if let frequent = data.frequent {
                    Button { store.push(.merchant(frequent.name)) } label: { highlightRow("Mais recorrente", "arrow.triangle.2.circlepath", frequent.name, "\(frequent.count)x · \(Noturno.money(frequent.total))") }
                }
                if let expensive = data.expensive {
                    Button { store.openDay(expensive.date) } label: { highlightRow("Dia mais caro", "flame", Noturno.date(expensive.date, "EEE, dd MMM"), Noturno.money(expensive.total)) }
                }
                if let busiest = data.busiest {
                    Button { store.openDay(busiest.date) } label: { highlightRow("Dia mais movimentado", "calendar", Noturno.date(busiest.date, "EEE, dd MMM"), "\(busiest.count) lançamentos") }
                }
            }.nightCard()
        }
    }
    private func highlightRow(_ title: String, _ icon: String, _ value: String, _ subtitle: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(Noturno.amber).frame(width: 30)
            Text(title).font(.caption).foregroundStyle(Noturno.secondary)
            Spacer()
            VStack(alignment: .trailing) { Text(value).font(.subheadline.bold()); Text(subtitle).font(.caption2).foregroundStyle(Noturno.secondary) }
        }
    }
}
private struct HeroPositionKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
struct NightChip: View {
    let title: String
    let selected: Bool
    var category: String? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let category { NightTile(category: category) }
                Text(title).font(.caption.weight(.semibold))
            }.padding(.horizontal, 12).padding(.vertical, 8)
                .foregroundStyle(selected ? category.map { Color.forCategory($0) } ?? Noturno.text : Noturno.secondary)
                .background(selected ? (category.map { Color.forCategory($0) } ?? Noturno.text).opacity(0.12) : Noturno.surface2, in: Capsule())
        }.sensoryFeedback(.selection, trigger: selected)
    }
}
struct NightMerchantRow: View {
    let merchant: NightMerchant
    let total: Double
    var body: some View {
        HStack {
            NightTile(category: merchant.category)
            VStack(alignment: .leading, spacing: 6) {
                HStack { Text(merchant.name).font(.subheadline.bold()); if merchant.count > 1 { Text("\(merchant.count)x").font(.caption2.bold()).foregroundStyle(Color.forCategory(merchant.category)) } }
                GeometryReader { proxy in Capsule().fill(Color.forCategory(merchant.category)).frame(width: max(0, proxy.size.width * min(1, merchant.total / max(total, 0.01)))) }.frame(height: 4).background(Noturno.surface2)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(Noturno.money(merchant.total)).moneyFont(16)
                Text("\(Int(merchant.total / max(total, 0.01) * 100))%").font(.caption2).foregroundStyle(Noturno.secondary)
            }
        }.padding(.vertical, 10).contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityValue(merchant.category)
    }
}
func deltaLabel(_ delta: Double, month: YearMonth) -> some View {
    let previous = NightDates.calendar.date(byAdding: .month, value: -1, to: month.date)!
    return Text("\(delta > 0 ? "+" : "")\(Int((delta * 100).rounded()))% vs. \(Noturno.date(previous, "MMM"))")
        .font(.caption2.bold()).foregroundStyle(delta > 0 ? Noturno.amber : Noturno.secondary)
        .padding(5).background(Noturno.surface2, in: Capsule())
}

// Kept separate so the monthly card can be previewed at narrow widths and large text sizes.
private struct NightMonthlyComparison: View {
    let months: [NightMonth]
    let select: (YearMonth) -> Void
    @ScaledMetric(relativeTo: .caption2) private var rowHeight = 30.0

    private var spansYears: Bool { Set(months.map { $0.month.year }).count > 1 }
    private var maximum: Double { max(months.map(\.total).max() ?? 0, 0.01) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Por mês").font(.headline)
            VStack(spacing: 0) {
                ForEach(months.sorted { $0.month < $1.month }) { month in
                    Button { select(month.month) } label: {
                        NightMonthlyRowLayout(fraction: max(0, month.total / maximum), minimumHeight: rowHeight) {
                            Text(Noturno.date(month.month.date, spansYears ? "MMM yy" : "MMM").lowercased())
                                .font(.caption2.monospaced()).foregroundStyle(Noturno.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            monthlyBar(month)
                            Text(Noturno.money(month.total))
                                .fixedSize(horizontal: false, vertical: true)
                                .font(.caption2).monospacedDigit().foregroundStyle(Noturno.text)
                                .padding(.horizontal, 3)
                                .background(Noturno.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: 4))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(Noturno.date(month.month.date, "MMMM yyyy")), \(Noturno.money(month.total))")
                    .accessibilityHint("Filtrar o relatório por este mês")
                }
            }
            Text("Toque num mês para filtrar o relatório").font(.caption2).foregroundStyle(Noturno.secondary)
        }.nightCard()
    }

    private struct Segment: Identifiable {
        var id: String { name }
        let name: String
        let total: Double
    }

    private func segments(_ month: NightMonth) -> [Segment] {
        let expenses = month.cells.filter(\.inPeriod).compactMap(\.day).flatMap(\.expenses)
        let grouped = Dictionary(grouping: expenses, by: \.category)
        let totals: [Segment] = grouped.map { name, rows in
            let total = rows.reduce(0.0) { $0 + $1.value }
            return Segment(name: name, total: total)
        }.sorted { lhs, rhs in
            lhs.total == rhs.total ? lhs.name < rhs.name : lhs.total > rhs.total
        }
        // Keep up to five substantial categories and merge small slices into neutral gray.
        let major = Array(totals.prefix(5).filter { $0.total / max(month.total, 0.01) >= 0.05 })
        let remainder = month.total - major.reduce(0) { $0 + $1.total }
        return remainder > 0 ? major + [Segment(name: "Outras", total: remainder)] : major
    }

    private func monthlyBar(_ month: NightMonth) -> some View {
        let segments = segments(month)
        return GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(segments) { segment in
                    Rectangle().fill(Color.forCategory(segment.name))
                        .frame(width: max(0, geometry.size.width * segment.total / max(month.total, 0.01)))
                        .accessibilityLabel("\(segment.name), \(Noturno.money(segment.total))")
                }
            }.clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

private struct NightMonthlyRowLayout: Layout {
    let fraction: Double
    let minimumHeight: CGFloat
    private let gap: CGFloat = 6

    private struct Metrics {
        let label: CGSize
        let value: CGSize
        let barWidth: CGFloat
        let valueX: CGFloat
        let height: CGFloat
    }

    private func metrics(width: CGFloat, subviews: Subviews) -> Metrics {
        let label = subviews[0].sizeThatFits(.init(width: min(subviews[0].sizeThatFits(.unspecified).width, width * 0.35), height: nil))
        let lane = max(0, width - label.width - gap)
        let barWidth = lane * min(1, max(0, fraction))
        let outside = max(0, lane - barWidth - gap)
        let inside = max(0, barWidth - 2 * gap)
        let value = subviews[2].sizeThatFits(.init(width: max(1, max(outside, inside)), height: nil))
        let valueX = value.width <= outside ? barWidth + gap : max(gap, barWidth - gap - value.width)
        return Metrics(label: label, value: value, barWidth: barWidth, valueX: valueX,
                       height: max(minimumHeight, max(label.height, value.height) + 8))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 280
        return CGSize(width: width, height: metrics(width: width, subviews: subviews).height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let m = metrics(width: bounds.width, subviews: subviews)
        let start = bounds.minX + m.label.width + gap
        subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading,
                          proposal: .init(width: m.label.width, height: m.label.height))
        subviews[1].place(at: CGPoint(x: start, y: bounds.midY), anchor: .leading,
                          proposal: .init(width: m.barWidth, height: m.height - 8))
        subviews[2].place(at: CGPoint(x: start + m.valueX, y: bounds.midY), anchor: .leading,
                          proposal: .init(width: m.value.width, height: m.value.height))
    }
}

private func monthlyComparisonPreview(start: String = "01/01/2026") -> [NightMonth] {
    let totals = [235.79, 299.27, 42.50, 0, 2_399.90, 786.20, 1_234.56, 945.10]
    let date = NightDates.parse(start)!
    return totals.enumerated().map { index, total in
        let day = NightDates.calendar.date(byAdding: .month, value: index, to: date)!
        let categories = ["Supermercado", "Moradia / Contas", "Restaurante / Lanches", "Transporte / Auto", "Saúde / Farmácia / Bem-estar", "Roupas / Acessórios", "Lazer / Entretenimento / Pets"]
        let weights = [0.30, 0.25, 0.20, 0.12, 0.06, 0.04, 0.03]
        let expenses = zip(categories, weights).enumerated().map { offset, part in
            NightExpense(id: index * 10 + offset, name: part.0, date: day, value: total * part.1, category: part.0)
        }
        return NightMonth(month: YearMonth(day),
                          cells: [NightCalendarCell(date: day, number: 1, day: NightDay(date: day, expenses: expenses, total: total), inPeriod: true, heat: 1)],
                          total: total, count: expenses.count, spendDays: total > 0 ? 1 : 0, partial: false, delta: nil)
    }
}

#Preview("Por mês · 8 meses · SE") {
    NightMonthlyComparison(months: monthlyComparisonPreview()) { _ in }
        .padding(16).frame(width: 320).background(.black).preferredColorScheme(.dark)
}

#Preview("Por mês · dois anos · texto ampliado") {
    ScrollView {
        NightMonthlyComparison(months: monthlyComparisonPreview(start: "01/10/2025")) { _ in }
            .padding(16)
    }
    .frame(width: 320).background(.black).preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility3)
}
