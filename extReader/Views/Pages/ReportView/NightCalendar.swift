import SwiftUI

struct NightCalendar: View {
    let data: FilteredReport
    @EnvironmentObject private var store: NightReportStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var weekly = false
    @State private var page: YearMonth?
    @State private var appeared = false
    @State private var selectedGridDay: Date?
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(data.calendars.count > 1 ? "Seus meses" : "Seu mês").font(.headline)
                Spacer()
                if data.calendars.count > 1 {
                    Picker("Calendário", selection: $weekly) { Text("Mês").tag(false); Text("Semanas").tag(true) }.pickerStyle(.segmented).frame(maxWidth: 150)
                }
            }
            if weekly { weekGrid }
            else if data.calendars.count > 1 { carousel }
            else if let month = data.calendars.first { monthCard(month) }
        }.onAppear {
            weekly = data.span > 93 || data.calendars.count > 3
            page = store.month ?? data.calendars.last?.month
            appeared = true
        }
    }
    private var carousel: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(data.calendars) { month in
                        monthCard(month).containerRelativeFrame(.horizontal) { width, _ in width - 24 }
                            .scrollTransition { content, phase in content.opacity(phase.isIdentity ? 1 : 0.4).scaleEffect(phase.isIdentity ? 1 : 0.94) }
                            .id(month.month)
                    }
                }.scrollTargetLayout()
            }.scrollTargetBehavior(.viewAligned).scrollPosition(id: $page)
            HStack(spacing: 5) {
                ForEach(data.calendars) { month in
                    Capsule().fill(page == month.month ? Noturno.text : Noturno.tertiary).frame(width: page == month.month ? 16 : 6, height: 6)
                }
            }.accessibilityHidden(true)
            Text("Deslize para trocar de mês · toque num dia para abrir").font(.caption2).foregroundStyle(Noturno.secondary)
        }
    }
    private func monthCard(_ month: NightMonth) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(Noturno.date(month.month.date, "MMMM yyyy").capitalized)\(month.partial ? " (parcial)" : "")").font(.subheadline.bold())
                Spacer()
                if data.calendars.count > 1 { Text(Noturno.money(month.total)).moneyFont(14) }
            }
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(Array("DSTQQSS").indices, id: \.self) { index in Text(String(Array("DSTQQSS")[index])).font(.caption2).foregroundStyle(Noturno.secondary) }
                ForEach(Array(month.cells.enumerated()), id: \.element.id) { index, cell in
                    cellView(cell, compact: false)
                        .opacity(appeared || reduceMotion || data.expenses.count > 300 ? 1 : 0)
                        .animation(reduceMotion || data.expenses.count > 300 ? nil : Noturno.spring.delay(Double(index / 7 + index % 7) * 0.025), value: appeared)
                }
            }
            HStack {
                Label("maior compra", systemImage: "circle.fill").font(.system(size: 9)).foregroundStyle(Noturno.amber)
                Spacer()
                heatLegend
            }
            if data.calendars.count > 1 {
                HStack {
                    Text("\(month.spendDays) dias com gasto · \(month.count) lançamentos")
                    Spacer()
                    Text("média \(Noturno.money(month.total / Double(max(1, month.spendDays))))")
                }.font(.caption2).foregroundStyle(Noturno.secondary).padding(.top, 6)
            }
        }.nightCard()
    }
    private var weekGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(data.weekCells.count) semanas · cada quadrado é um dia").font(.caption).foregroundStyle(Noturno.secondary)
            ScrollViewReader { reader in
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            ForEach(data.weekCells.indices, id: \.self) { index in
                                Text(data.weekCells[index].contains(where: { $0.number == 1 }) ? Noturno.date(data.weekCells[index].last!.date, "MMM") : " ")
                                    .font(.system(size: 8)).foregroundStyle(Noturno.secondary).frame(width: 19)
                            }
                        }
                        LazyHGrid(rows: Array(repeating: GridItem(.fixed(19), spacing: 4), count: 7), spacing: 4) {
                            ForEach(data.weekFlatCells) { cell in cellView(cell, compact: true).id(cell.date) }
                        }
                        HStack(alignment: .bottom, spacing: 4) {
                            ForEach(data.weekCells.indices, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 3).fill(Noturno.amber.opacity(0.7))
                                    .frame(width: 19, height: max(3, 40 * data.weekTotals[index] / max(data.maxWeekTotal, 0.01)))
                                    .frame(height: 42, alignment: .bottom)
                            }
                        }
                    }

                }.onAppear { reader.scrollTo(data.weekFlatCells.last?.date, anchor: .trailing) }
            }
            if let date = selectedGridDay, let day = data.dayLookup[date] {
                Button { store.openDay(date) } label: {
                    HStack {
                        VStack(alignment: .leading) { Text(Noturno.date(date, "EEE, dd MMM")).font(.subheadline.bold()); Text("\(day.count) lançamentos").font(.caption2).foregroundStyle(Noturno.secondary) }
                        Spacer(); Text(Noturno.money(day.total)).moneyFont(18)
                    }.padding(.vertical, 8)
                }
            }
            heatLegend.frame(maxWidth: .infinity, alignment: .trailing)
            Text("Períodos com mais de 3 meses usam a grade semanal").font(.caption2).foregroundStyle(Noturno.secondary)
        }.nightCard()
    }
    private var heatLegend: some View {
        HStack(spacing: 3) {
            Text("menos")
            ForEach(0..<5) { level in RoundedRectangle(cornerRadius: 2).fill(heatColor(level)).frame(width: 8, height: 8) }
            Text("mais")
        }.font(.system(size: 9)).foregroundStyle(Noturno.secondary)
    }
    private func cellView(_ cell: NightCalendarCell, compact: Bool) -> some View {
        Button {
            if let day = cell.day { selectedGridDay = day.date; store.openDay(day.date) }
        } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: compact ? 5 : 11).fill(cell.inPeriod ? heatColor(cell.heat) : Color(hex: 0x0C0D0D))
                if !compact {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 1) {
                            Text("\(cell.number)").font(.system(size: 10, weight: .semibold))
                            Spacer(minLength: 0)
                            if cell.date == data.biggest?.date { Circle().fill(Noturno.amber).frame(width: 4, height: 4) }
                        }
                        if let day = cell.day { Text(day.total.formatted(.number.precision(.fractionLength(0)).locale(Locale(identifier: "pt_BR")))).font(.system(size: 10, weight: .heavy, design: .rounded)).minimumScaleFactor(0.5).frame(maxWidth: .infinity) }
                    }.padding(4).foregroundStyle(cell.heat == 4 ? Color(hex: 0x211A10) : (cell.inPeriod ? Noturno.text : Noturno.tertiary))
                }
            }.frame(width: compact ? 19 : nil, height: compact ? 19 : 40)
                .overlay(RoundedRectangle(cornerRadius: compact ? 5 : 11).stroke(store.highlightedDay == cell.date ? .white : .clear, lineWidth: 2))
        }.disabled(cell.day == nil || !cell.inPeriod)
            .accessibilityLabel("\(Noturno.date(cell.date, "EEEE, dd 'de' MMMM")), \(Noturno.money(cell.day?.total ?? 0)), \(cell.day?.count ?? 0) lançamentos")
    }
}
func heatColor(_ level: Int) -> Color {
    level == 0 ? Color(hex: 0x161918) : Noturno.amber.opacity([0.0, 0.22, 0.42, 0.70, 1.0][min(4, max(0, level))])
}
