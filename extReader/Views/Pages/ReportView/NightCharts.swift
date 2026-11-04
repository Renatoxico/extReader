import SwiftUI
import Charts

struct ArcSegment: Shape {
    var start: Double
    var end: Double
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width / 2, rect.height)
        path.addArc(center: CGPoint(x: rect.midX, y: rect.maxY), radius: max(0, radius - 16), startAngle: .degrees(180 + start), endAngle: .degrees(180 + end), clockwise: false)
        return path
    }
}
private struct GaugeSlice: Identifiable {
    var id: String { category.id }
    let category: NightCategory
    let start: Double
    let end: Double
}
struct NightCharts: View {
    let data: FilteredReport
    let namespace: Namespace.ID
    @EnvironmentObject private var store: NightReportStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tab = 0
    @State private var selected: String?
    @State private var expanded = false
    @State private var granularity: NightGranularity = .day
    @State private var selectedDate: Date?
    @State private var slices: [GaugeSlice] = []
    @State private var selectedBucket: NightBucket?
    @State private var selectedPoint: NightPoint?
    private var category: NightCategory? { data.visibleCategories.first { $0.id == selected } ?? data.visibleCategories.first }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Para onde foi").font(.largeTitle.bold())
                Text("\(Noturno.date(data.start)) – \(Noturno.date(data.end, "dd MMM yyyy"))").font(.caption).foregroundStyle(Noturno.secondary)
                Picker("Gráfico", selection: $tab) { Text("Categorias").tag(0); Text("Dias").tag(1); Text("Acumulado").tag(2) }.pickerStyle(.segmented)
                Group {
                    if tab == 0 { categories }
                    else if tab == 1 { days }
                    else { cumulative }
                }.transition(.opacity.combined(with: .scale(scale: 0.98)))
            }.padding(16)
        }.background { NoturnoBackground(tint: Noturno.amber) }
            .animation(reduceMotion ? nil : Noturno.spring, value: tab)
            .onAppear {
                granularity = data.automatic
                selectedBucket = data.buckets[data.automatic]?.last
                selectedPoint = data.cumulative.last
                var cursor = 0.0
                let weights = data.visibleCategories.map { max(4, $0.total / max(data.total, 0.01) * 180) }
                let sum = weights.reduce(0, +)
                slices = zip(data.visibleCategories, weights).map { cat, weight in
                    let width = weight / max(sum, 1) * 180
                    defer { cursor += width }
                    return GaugeSlice(category: cat, start: cursor + 1.5, end: cursor + max(1.6, width - 1.5))
                }
            }
            .onChange(of: selectedDate) { _, date in
                guard let date else { return }
                if tab == 1 { selectedBucket = data.buckets[granularity]?.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) } }
                else { selectedPoint = data.cumulative.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) } }
            }
            .onChange(of: granularity) { _, value in selectedBucket = data.buckets[value]?.last }
    }
    private func select(_ cat: NightCategory) {
        store.feedback += 1
        if !cat.members.isEmpty {
            selected = cat.id
            withAnimation(reduceMotion ? nil : Noturno.spring) { expanded.toggle() }
        } else if selected == cat.id { store.push(.category(cat.name)) }
        else { withAnimation(reduceMotion ? nil : Noturno.spring) { selected = cat.id } }
    }
    private var categories: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .bottom) {
                GeometryReader { geometry in
                    ZStack {
                        ForEach(slices) { slice in
                            ArcSegment(start: slice.start, end: slice.end).stroke(Color.forCategory(slice.category.name), style: StrokeStyle(lineWidth: selected == slice.id ? 30 : 24, lineCap: .round))
                        }
                        ForEach(1..<10) { tick in ArcSegment(start: Double(tick) * 18, end: Double(tick) * 18 + 0.3).stroke(.white.opacity(0.15), lineWidth: 3).padding(26) }
                    }.contentShape(Rectangle()).gesture(SpatialTapGesture().onEnded { event in
                        let dx = event.location.x - geometry.size.width / 2
                        let dy = event.location.y - geometry.size.height
                        let distance = sqrt(dx * dx + dy * dy)
                        let radius = min(geometry.size.width / 2, geometry.size.height) - 16
                        guard dy <= 0, abs(distance - radius) <= 32 else { return }
                        let angle = atan2(dy, dx) * 180 / .pi + 180
                        if let slice = slices.first(where: { angle >= $0.start - 1.5 && angle <= $0.end + 1.5 }) { select(slice.category) }
                    })
                }
                if let category {
                    VStack(spacing: 5) {
                        NightTile(category: category.name)
                        Text("\(category.name) · \(Int(category.total / max(data.total, 0.01) * 100))%").font(.caption.bold()).foregroundStyle(Color.forCategory(category.name))
                        Text(Noturno.money(category.total)).moneyFont(34).contentTransition(.numericText())
                        Text("de \(Noturno.money(data.total))").font(.caption2).foregroundStyle(Noturno.secondary)
                    }.padding(.bottom, 3).allowsHitTesting(false)
                }
            }.frame(height: expanded ? 150 : 200).padding(.horizontal, 4)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(category.map { "\($0.name), \(Noturno.money($0.total)). Toque na lista para explorar." } ?? "Categorias")
            if expanded {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading) {
                    ForEach(Array(data.visibleCategories.prefix(5))) { cat in
                        HStack(spacing: 4) {
                            NightTile(category: cat.name)
                            Text(cat.name).font(.caption2).foregroundStyle(Noturno.secondary)
                            Spacer(minLength: 0)
                            Text(Noturno.money(cat.total)).font(.caption2)
                        }
                    }
                }.nightCard()
            }
            VStack(spacing: 0) {
                ForEach(data.visibleCategories) { cat in
                    Button { select(cat) } label: { categoryRow(cat) }.nightZoomSource(id: cat.name, namespace: namespace)
                    if !cat.members.isEmpty && expanded {
                        HStack { Text("Outras · \(cat.members.count) categorias").font(.caption.bold()); Spacer(); Button("Recolher") { withAnimation { expanded = false } }.font(.caption) }.padding(.vertical, 14)
                        ForEach(cat.members) { member in
                            Button { store.push(.category(member.name)) } label: { categoryRow(member) }.nightZoomSource(id: member.name, namespace: namespace)
                        }
                    }
                }
            }.nightCard()
        }
    }
    private func categoryRow(_ cat: NightCategory) -> some View {
        HStack(alignment: .top) {
            NightTile(category: cat.name)
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cat.name).font(.subheadline.bold())
                        Text(cat.members.isEmpty ? "\(cat.count) lançamentos" : "\(cat.members.count) categorias menores").font(.caption2).foregroundStyle(Noturno.secondary)
                    }
                    Spacer(minLength: 4)
                    VStack(alignment: .trailing) {
                        Text(Noturno.money(cat.total)).moneyFont(15)
                        Text("\(Int(cat.total / max(data.total, 0.01) * 100))%").font(.caption2).foregroundStyle(Noturno.secondary)
                    }
                    if !cat.members.isEmpty { Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.caption2) }
                }
                GeometryReader { proxy in Capsule().fill(Color.forCategory(cat.name)).frame(width: proxy.size.width * min(1, cat.total / max(data.categories.first?.total ?? 1, 0.01))) }.frame(height: 4).background(Noturno.surface2)
            }
        }.padding(10).background(selected == cat.id ? Color.forCategory(cat.name).opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 16)).contentShape(Rectangle())
    }
    private var days: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ForEach(NightGranularity.allCases, id: \.self) { item in NightChip(title: item.rawValue, selected: granularity == item) { granularity = item; store.feedback += 1 } }
                Spacer(minLength: 0)
            }
            Text("automático: \(data.automatic.rawValue.lowercased())").font(.caption2).foregroundStyle(Noturno.secondary)
            VStack(alignment: .leading, spacing: 12) {
                Text("Por \(granularity.rawValue.lowercased())").font(.caption).foregroundStyle(Noturno.secondary)
                let buckets = data.buckets[granularity] ?? []
                Text(Noturno.money(data.bucketAverages[granularity] ?? 0)).moneyFont(24)
                Text(granularity == .day ? "média por dia com gasto" : "média por \(granularity.rawValue.lowercased()) com gasto").font(.caption2).foregroundStyle(Noturno.secondary)
                bucketChart(buckets)
            }.nightCard()
            if let bucket = selectedBucket {
                Button {
                    if granularity == .day { store.openDay(bucket.date) }
                    else { store.push(.allExpenses(bucket.date, bucket.end)) }
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(granularity == .day ? Noturno.date(bucket.date, "EEE, dd MMM") : "\(Noturno.date(bucket.date)) – \(Noturno.date(bucket.end))").font(.subheadline.bold())
                            Text(granularity == .day ? "Toque para abrir o dia" : "Ver despesas do período").font(.caption2).foregroundStyle(Noturno.secondary)
                        }
                        Spacer(); Text(Noturno.money(bucket.total)).moneyFont(18); Image(systemName: "chevron.right").font(.caption)
                    }.nightCard()
                }
            }
            Text("Arraste sobre o gráfico para selecionar").font(.caption2).foregroundStyle(Noturno.secondary)
        }
    }
    private func bucketChart(_ buckets: [NightBucket]) -> some View {
        Chart {
            ForEach(buckets) { bucket in
                BarMark(x: .value("Período", bucket.date, unit: granularity.component), y: .value("Valor", bucket.total))
                    .foregroundStyle(Noturno.amber.opacity(0.8)).cornerRadius(4)
                    .accessibilityLabel("\(Noturno.date(bucket.date)), \(Noturno.money(bucket.total))")
            }
            if granularity == .day && data.span <= 100 {
                ForEach(data.cumulative) { point in
                    if !point.spent { RectangleMark(x: .value("Dia", point.date, unit: .day), yStart: .value("Base", 0), yEnd: .value("Sem gasto", max(1, data.average * 0.015))).foregroundStyle(Noturno.tertiary.opacity(0.3)) }
                }
            }
            RuleMark(y: .value("Média", data.bucketAverages[granularity] ?? 0)).lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3])).foregroundStyle(Noturno.secondary)
            if let selectedBucket {
                RuleMark(x: .value("Selecionado", selectedBucket.date)).foregroundStyle(.white.opacity(0.15))
            }
            if data.calendars.count > 1 {
                ForEach(data.calendars) { month in
                    RuleMark(x: .value("Mês", month.month.date)).lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4])).foregroundStyle(.white.opacity(0.14)).annotation(position: .top) { Text(Noturno.date(month.month.date, "MMM")).font(.system(size: 9)).foregroundStyle(Noturno.secondary) }
                }
            }
        }.chartXSelection(value: $selectedDate)
            .chartYAxis(.hidden).chartXAxis { AxisMarks(values: .automatic(desiredCount: 6)) { AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true) } }
            .modifier(NightChartScroll(enabled: granularity == .week && buckets.count > 26))
            .frame(height: 270)
    }
    private var cumulative: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Acumulado no período").font(.caption).foregroundStyle(Noturno.secondary)
                Text(Noturno.money(data.total)).moneyFont(28)
                Chart {
                    ForEach(Array(data.calendars.enumerated()), id: \.element.id) { index, month in
                        if index % 2 == 0 { RectangleMark(xStart: .value("Início", max(data.start, month.month.date)), xEnd: .value("Fim", min(data.end, month.month.end))).foregroundStyle(.white.opacity(0.025)) }
                        if data.calendars.count > 1 {
                            RuleMark(x: .value("Mês", month.month.date)).foregroundStyle(.white.opacity(0.14)).lineStyle(StrokeStyle(dash: [3, 4])).annotation(position: .top) { Text(Noturno.date(month.month.date, "MMM")).font(.system(size: 9)) }
                        }
                    }
                    ForEach(data.chartPoints) { point in
                        AreaMark(x: .value("Dia", point.date), y: .value("Acumulado", point.total)).foregroundStyle(LinearGradient(colors: [Noturno.amber.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom))
                        LineMark(x: .value("Dia", point.date), y: .value("Acumulado", point.total), series: .value("Série", "Gastos")).foregroundStyle(Noturno.amber).lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                    ForEach(data.monthEndPoints) { point in PointMark(x: .value("Dia", point.date), y: .value("Acumulado", point.total)).foregroundStyle(.white).symbolSize(20) }
                    ForEach([NightPoint(date: data.start, total: 0, spent: false), NightPoint(date: data.end, total: data.total, spent: false)]) { point in
                        LineMark(x: .value("Dia", point.date), y: .value("Ritmo", point.total), series: .value("Série", "Ritmo constante")).foregroundStyle(Noturno.secondary.opacity(0.6)).lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                    if let point = selectedPoint {
                        RuleMark(x: .value("Seleção", point.date)).foregroundStyle(.white.opacity(0.4))
                        PointMark(x: .value("Dia", point.date), y: .value("Acumulado", point.total)).foregroundStyle(Noturno.text).symbolSize(45)
                            .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                                VStack { Text("até \(Noturno.date(point.date, "EEE, dd MMM"))").font(.caption2); Text(Noturno.money(point.total)).font(.caption.bold()) }.padding(8).background(Noturno.surface2, in: RoundedRectangle(cornerRadius: 10))
                            }
                    }
                }.chartXSelection(value: $selectedDate).chartYAxis(.hidden).chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { AxisValueLabel(format: .dateTime.day().month(.abbreviated)) } }.frame(height: 300)
                Text("━ seus gastos    ┄ ritmo constante    ● fim do mês").font(.caption2).foregroundStyle(Noturno.secondary)
            }.nightCard()
            if let half = data.halfDate {
                Text("Metade do total saiu até \(Noturno.date(half)), dia \((NightDates.calendar.dateComponents([.day], from: data.start, to: half).day ?? 0) + 1) de \(data.span + 1).")
                    .font(.caption).foregroundStyle(Noturno.secondary).frame(maxWidth: .infinity, alignment: .leading).nightCard()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack { ForEach(data.calendars) { month in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(Noturno.date(month.month.date, "MMMM").capitalized).font(.caption).foregroundStyle(Noturno.secondary)
                        Text(Noturno.money(month.total)).moneyFont(16)
                        if let delta = month.delta { deltaLabel(delta, month: month.month) }
                    }.nightCard()
                } }
            }
        }.onAppear { if selectedDate == nil { selectedPoint = data.cumulative.first { $0.date == data.expensive?.date } } }
    }
}

private struct NightChartScroll: ViewModifier {
    let enabled: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if enabled { content.chartScrollableAxes(.horizontal).chartXVisibleDomain(length: 26 * 7 * 86400) }
        else { content }
    }
}
