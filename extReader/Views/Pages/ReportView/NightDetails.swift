import SwiftUI
import Charts

struct NightExpenseRow: View {
    let expense: NightExpense
    let data: FilteredReport
    var body: some View {
        HStack(spacing: 10) {
            NightTile(category: expense.category)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(expense.name).font(.subheadline.bold()).lineLimit(2)
                    if data.recurring.contains(expense.name) {
                        Text("↻ \(data.occurrence[expense.id] ?? 1)ª").font(.system(size: 10, weight: .bold)).foregroundStyle(Noturno.secondary)
                            .padding(.horizontal, 5).padding(.vertical, 2).background(Noturno.secondary.opacity(0.18), in: Capsule())
                    }
                }
                Text(expense.category).font(.caption2).foregroundStyle(Noturno.secondary)
            }
            Spacer(minLength: 4)
            Text(Noturno.money(expense.value)).moneyFont(16).lineLimit(1)
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Noturno.surface, in: RoundedRectangle(cornerRadius: 16)).contentShape(Rectangle())
    }
}
struct NightCategoryDetail: View {
    let data: FilteredReport
    let name: String
    @EnvironmentObject private var store: NightReportStore
    private var detail: NightDetail? { data.categoryReports[name] }
    private var color: Color { Color.forCategory(name) }
    var body: some View {
        ScrollView {
            if let detail {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 18) {
                        ZStack {
                            Circle().stroke(color.opacity(0.12), lineWidth: 8)
                            Circle().trim(from: 0, to: min(1, detail.total / max(data.total, 0.01))).stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90))
                            NightTile(category: name)
                        }.frame(width: 76, height: 76)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(name).font(.title2.bold())
                            Text(Noturno.money(detail.total)).moneyFont(30)
                            Text("\(Int(detail.total / max(data.total, 0.01) * 100))% do total · \(detail.expenses.count) lançamentos").font(.caption).foregroundStyle(Noturno.secondary)
                        }
                    }
                    HStack(spacing: 6) {
                        NightStat(label: "Média", value: Noturno.money(detail.total / Double(max(1, detail.expenses.count))))
                        NightStat(label: "Maior", value: Noturno.money(detail.largest))
                        NightStat(label: "Dias", value: "\(detail.days.count)")
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dia a dia").font(.headline)
                        Chart(detail.days) { day in
                            BarMark(x: .value("Dia", day.date, unit: .day), y: .value("Valor", day.total))
                                .foregroundStyle(LinearGradient(colors: [color, color.opacity(0.55)], startPoint: .top, endPoint: .bottom)).cornerRadius(5)
                                .annotation(position: .top) { Text(day.total.formatted(.number.precision(.fractionLength(0)))).font(.system(size: 9, weight: .bold)) }
                                .accessibilityLabel("\(Noturno.date(day.date)), \(Noturno.money(day.total))")
                        }.chartXScale(domain: data.start...max(data.end, data.start.addingTimeInterval(86400)))
                            .chartYAxis(.hidden).chartXAxis { AxisMarks(values: .automatic(desiredCount: 5)) { AxisValueLabel(format: .dateTime.day()) } }.frame(height: 160)
                    }.nightCard()
                    Text("LANÇAMENTOS").font(.caption.bold()).foregroundStyle(Noturno.secondary)
                    LazyVStack(spacing: 8) {
                        ForEach(detail.expenses) { expense in
                            Button { store.openDay(expense.date) } label: {
                                HStack {
                                    VStack { Text(Noturno.date(expense.date, "dd")).moneyFont(17); Text(Noturno.date(expense.date, "EEE")).font(.caption2).foregroundStyle(Noturno.secondary) }.frame(width: 30)
                                    VStack(alignment: .leading) { Text(expense.name).font(.subheadline.bold()); Text("\(Int(expense.value / max(detail.total, 0.01) * 100))% da categoria").font(.caption2).foregroundStyle(Noturno.secondary) }
                                    Spacer(); Text(Noturno.money(expense.value)).moneyFont()
                                }.nightCard()
                            }.nightExpenseActions(expense)
                        }
                    }
                    Text("ESTABELECIMENTOS").font(.caption.bold()).foregroundStyle(Noturno.secondary)
                    LazyVStack {
                        ForEach(detail.merchants) { merchant in
                            Button { store.push(.merchant(merchant.name)) } label: { NightMerchantRow(merchant: merchant, total: detail.total).nightCard() }
                        }
                    }
                }.padding(16)
            } else {
                ContentUnavailableView("Nenhuma despesa nesta categoria", systemImage: "tag")
            }
        }.background { NoturnoBackground(tint: color, top: true) }.navigationTitle("").navigationBarTitleDisplayMode(.inline)
    }
}
struct NightDaySheet: View {
    let data: FilteredReport
    @State private var date: Date
    @EnvironmentObject private var store: NightReportStore
    init(data: FilteredReport, initialDate: Date) { self.data = data; _date = State(initialValue: initialDate) }
    private var day: NightDay? { data.dayLookup[date] }
    private var index: Int { data.days.firstIndex { $0.date == date } ?? 0 }
    var body: some View {
        ScrollView {
            if let day {
                VStack(spacing: 18) {
                    HStack {
                        Button { move(-1) } label: { Image(systemName: "chevron.left").frame(width: 36, height: 36).background(.white.opacity(0.05), in: Circle()) }.disabled(index == 0).opacity(index == 0 ? 0.3 : 1)
                        Spacer()
                        VStack(spacing: 4) {
                            Text(Noturno.date(date, "EEEE, dd MMM")).font(.headline)
                            Text(dayLabel).font(.caption2).foregroundStyle(Noturno.secondary)
                        }
                        Spacer()
                        Button { move(1) } label: { Image(systemName: "chevron.right").frame(width: 36, height: 36).background(.white.opacity(0.05), in: Circle()) }.disabled(index >= data.days.count - 1).opacity(index >= data.days.count - 1 ? 0.3 : 1)
                    }
                    Text(Noturno.money(day.total)).moneyFont(40)
                    let delta = data.average == 0 ? 0 : (day.total / data.average - 1) * 100
                    Text("\(day.count) lançamentos · \(delta > 0 ? "+" : "")\(Int(delta.rounded()))% vs. média por dia com gasto")
                        .font(.caption).foregroundStyle(delta > 0 ? Noturno.amber : Noturno.secondary).multilineTextAlignment(.center)
                    NightProportionBar(categories: data.dayCategories[day.date] ?? [], total: day.total)
                    ForEach(day.expenses) { expense in
                        Button { store.fromSheet(data.recurring.contains(expense.name) ? .merchant(expense.name) : .expense(expense.id)) } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                NightExpenseRow(expense: expense, data: data)
                                if data.recurring.contains(expense.name) { Text("\(data.occurrence[expense.id] ?? 1)ª vez no período").font(.caption2).foregroundStyle(Noturno.secondary).padding(.leading, 58) }
                            }
                        }.nightExpenseActions(expense)
                    }
                    Button { store.fromSheet(.allExpenses(nil, nil), focus: date) } label: {
                        Text("Ver na linha do tempo").font(.subheadline.bold()).frame(maxWidth: .infinity).padding(14).foregroundStyle(Noturno.emerald).background(Noturno.emerald.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                    }
                }.padding(20).padding(.top, 12)
            } else {
                ContentUnavailableView("Nenhuma despesa neste dia", systemImage: "calendar", description: Text("Os totais do relatório já foram atualizados."))
            }
        }.background(LinearGradient(colors: [Color(hex: 0x1A1D1B), Color(hex: 0x121413)], startPoint: .top, endPoint: .bottom))
            .gesture(DragGesture(minimumDistance: 40).onEnded { value in
                if abs(value.translation.width) > abs(value.translation.height) { move(value.translation.width < 0 ? 1 : -1) }
            })
            .onChange(of: date) { _, value in store.highlightedDay = value }
    }
    private var dayLabel: String {
        var labels: [String] = []
        if date == data.busiest?.date { labels.append("Dia mais movimentado") }
        if date == data.expensive?.date { labels.append("Dia mais caro") }
        return labels.joined(separator: " · ")
    }
    private func move(_ step: Int) {
        let next = index + step
        guard data.days.indices.contains(next) else { return }
        date = data.days[next].date; store.feedback += 1
    }

}
struct NightMerchantDetail: View {
    let data: FilteredReport
    let name: String
    @EnvironmentObject private var store: NightReportStore
    private var merchant: NightMerchant? { data.merchantLookup[name] }
    var body: some View {
        ScrollView {
            if let merchant {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 14) {
                        NightTile(category: merchant.category).scaleEffect(1.3).padding(8)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name).font(.title2.bold())
                            Text("\(merchant.category)\(merchant.count > 1 ? " · ↻ recorrente" : "")").font(.caption).foregroundStyle(Color.forCategory(merchant.category))
                        }
                    }
                    Text(Noturno.money(merchant.total)).moneyFont(42)
                    Text("\(merchant.count) compras · \(Int(merchant.total / max(data.total, 0.01) * 100))% do total do período").font(.caption).foregroundStyle(Noturno.secondary)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quando você comprou").font(.headline)
                        Chart {
                            RuleMark(y: .value("Eixo", 0)).foregroundStyle(Color.forCategory(merchant.category).opacity(0.5)).lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
                            ForEach(merchant.expenses) { expense in
                                PointMark(x: .value("Dia", expense.date), y: .value("Compra", 0)).symbolSize(180 + 600 * expense.value / max(data.biggest?.value ?? 1, 0.01)).foregroundStyle(Color.forCategory(merchant.category))
                                    .annotation(position: .overlay) { Text("\(data.occurrence[expense.id] ?? 1)ª").font(.system(size: 10, weight: .heavy)).foregroundStyle(.black) }
                                    .annotation(position: .top) { if merchant.count <= 8 { Text(Noturno.money(expense.value)).font(.system(size: 9, weight: .bold)) } }
                                    .accessibilityLabel("\(data.occurrence[expense.id] ?? 1)ª compra, \(Noturno.date(expense.date)), \(Noturno.money(expense.value))")
                            }
                        }.chartXScale(domain: data.start.addingTimeInterval(-86400)...data.end.addingTimeInterval(86400)).chartYScale(domain: -1...1).chartYAxis(.hidden).chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { AxisValueLabel(format: .dateTime.day().month(.abbreviated)) } }.frame(height: 115)
                        if merchant.count > 1 { Text("\(merchant.interval) dias entre compras, em média").font(.caption2).foregroundStyle(Color.forCategory(merchant.category)) }
                    }.nightCard()
                    HStack(spacing: 6) {
                        NightStat(label: "Por compra", value: Noturno.money(merchant.total / Double(max(1, merchant.count))))
                        NightStat(label: "Intervalo", value: merchant.count > 1 ? "\(merchant.interval) dias" : "—")
                        NightStat(label: "Da categoria", value: "\(Int(merchant.total / max(data.categoryReports[merchant.category]?.total ?? merchant.total, 0.01) * 100))%")
                    }
                    Text("COMPRAS").font(.caption.bold()).foregroundStyle(Noturno.secondary)
                    LazyVStack(spacing: 8) {
                        ForEach(merchant.expenses) { expense in
                            Button { store.push(.expense(expense.id)) } label: {
                                HStack {
                                    Text("\(data.occurrence[expense.id] ?? 1)ª").font(.caption.bold()).foregroundStyle(Color.forCategory(merchant.category))
                                    VStack(alignment: .leading) { Text(Noturno.date(expense.date, "EEE, dd MMM")).font(.subheadline.bold()); Text(data.occurrence[expense.id] == 1 ? "primeira no período" : "\(data.intervalDays[expense.id] ?? 0) dias depois").font(.caption2).foregroundStyle(Noturno.secondary) }
                                    Spacer(); Text(Noturno.money(expense.value)).moneyFont()
                                }.nightCard()
                            }.nightExpenseActions(expense)
                        }
                    }
                }.padding(16)
            } else {
                ContentUnavailableView("Nenhuma despesa neste estabelecimento", systemImage: "storefront")
            }
        }.background { NoturnoBackground(tint: Color.forCategory(merchant?.category ?? ""), top: true) }.navigationBarTitleDisplayMode(.inline)
    }
}
