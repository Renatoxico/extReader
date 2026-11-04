import SwiftUI

enum ReportRoute: Hashable {
    case charts, category(String), merchant(String), allExpenses(Date?, Date?), expense(Int)
}
struct SelectedNightDay: Identifiable {
    let id: Date
}
struct ExpenseReportViewTabs: View {
    let report: ExpenseResponse
    var initialRoute: ReportRoute? = nil
    @StateObject private var store = NightReportStore()
    @Namespace private var categoryNamespace
    @State private var addingExpense = false
    @State private var sharing = false
    @State private var showAmounts = false
    @State private var activity: SharePayload?
    @State private var exportError = false
    @State private var exporting = false
    @State private var temporaryCSV: URL?
    @State private var dismissedWarning = false
    var body: some View {
        NavigationStack(path: $store.path) {
            ZStack {
                NoturnoBackground(tint: Noturno.amber)
                if let data = store.current {
                    NightDashboard(data: data)
                        .id(store.month?.id ?? "all")
                        .navigationDestination(for: ReportRoute.self) { route in
                            destination(route, data: data)
                        }
                } else { ProgressView("Preparando relatório…") }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { addingExpense = true } label: {
                        Image(systemName: "plus").frame(width: 36, height: 36).background(Noturno.surface2, in: Circle())
                    }.accessibilityLabel("Adicionar despesa").disabled(store.report == nil || store.isSaving)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAmounts = false; sharing = true } label: {
                        Image(systemName: "square.and.arrow.up").frame(width: 36, height: 36)
                            .background(Noturno.surface2, in: Circle())
                    }.accessibilityLabel("Compartilhar relatório")
                }
            }
            .sheet(isPresented: $addingExpense) { NightAddExpenseView() }
            .overlay(alignment: .bottom) {
                if store.isSaving { ProgressView("Salvando…").padding().background(Noturno.surface2, in: Capsule()).padding() }
            }
            .sheet(isPresented: $sharing) {
                if let data = store.current {
                    NavigationStack {
                        ScrollView {
                            VStack(spacing: 20) {
                                NightShareHero(data: data, showAmounts: showAmounts)
                                Toggle("Mostrar valores", isOn: $showAmounts)
                                Button("Compartilhar imagem", systemImage: "square.and.arrow.up") {
                                    let renderer = ImageRenderer(content: NightShareHero(data: data, showAmounts: showAmounts).frame(width: 360).padding().background(.black).environment(\.colorScheme, .dark))
                                    renderer.scale = 3
                                    if let image = renderer.uiImage { activity = SharePayload(items: [image]) }
                                }
                                Button { Task { await exportCSV() } } label: {
                                    if exporting { ProgressView() } else { Label("Exportar CSV", systemImage: "tablecells") }
                                }.disabled(exporting)
                            }.padding()
                        }.background(.black).navigationTitle("Compartilhar")
                            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { sharing = false } } }
                            .sheet(item: $activity, onDismiss: cleanupCSV) { payload in ShareSheet(activityItems: payload.items) }
                    }
                }
            }
            .sheet(item: $store.selectedDay, onDismiss: { store.highlightedDay = nil }) { selected in
                if let data = store.current {
                    NightDaySheet(data: data, initialDate: selected.id)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                        .presentationBackground(.ultraThinMaterial)
                        .presentationCornerRadius(28)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if let data = store.current, data.categories.contains(where: { $0.name == "Outros / Transferências" }), !dismissedWarning {
                    HStack {
                        Text("Há despesas sem categoria.").font(.caption)
                        Spacer()
                        Button("Dispensar", systemImage: "xmark") { dismissedWarning = true }.labelStyle(.iconOnly)
                    }.padding(10).background(Noturno.surface)
                }
            }
            .alert("Erro", isPresented: $exportError) { Button("OK", role: .cancel) {} } message: { Text("Não foi possível exportar o relatório.") }
        }
        .environmentObject(store)
        .preferredColorScheme(.dark)
        .tint(Noturno.emerald)
        .foregroundStyle(Noturno.text)
        .buttonStyle(NoturnoPress())
        .sensoryFeedback(.selection, trigger: store.feedback)
        .task(id: report.sessionToken) {
            await store.load(report)
            if let initialRoute, store.path.isEmpty { store.path = [initialRoute] }
        }
    }
    @ViewBuilder private func destination(_ route: ReportRoute, data: FilteredReport) -> some View {
        switch route {
        case .charts: NightCharts(data: data, namespace: categoryNamespace)
        case .category(let name): NightCategoryDetail(data: data, name: name).nightZoom(id: name, namespace: categoryNamespace)
        case .merchant(let name): NightMerchantDetail(data: data, name: name)
        case .allExpenses(let start, let end): NightExpenseTimeline(data: data, rangeStart: start, rangeEnd: end)
        case .expense(let id):
            if let expense = store.expense(id) { ExpenseDetailView(expense: expense) }
            else { ContentUnavailableView("Despesa excluída", systemImage: "receipt") }
        }
    }
    private func exportCSV() async {
        exporting = true
        defer { exporting = false }
        do {
            let csv = try await ExpenseService.shared.exportCSV(sessionId: store.report?.sessionToken ?? report.sessionToken)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("despesas-\(UUID().uuidString).csv")
            try csv.write(to: url); temporaryCSV = url; activity = SharePayload(items: [url])
        } catch { exportError = true }
    }
    private func cleanupCSV() { if let url = temporaryCSV { try? FileManager.default.removeItem(at: url) }; temporaryCSV = nil }
}
private struct SharePayload: Identifiable { let id = UUID(); let items: [Any] }
struct NightShareHero: View {
    let data: FilteredReport
    let showAmounts: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Somaí · RELATÓRIO").font(.headline).foregroundStyle(Noturno.emerald)
            Text("\(Noturno.date(data.start)) – \(Noturno.date(data.end, "dd MMM yyyy"))").font(.caption).foregroundStyle(Noturno.secondary)
            Text(showAmounts ? Noturno.money(data.total) : "R$ •••").moneyFont(40)
            NightProportionBar(categories: data.visibleCategories, total: data.total)
            Text("\(data.expenses.count) lançamentos · \(data.merchants.count) estabelecimentos").font(.caption)
            if let biggest = data.biggest {
                Text("Maior compra").foregroundStyle(Noturno.secondary)
                Text(biggest.name).font(.headline)
                Text(showAmounts ? Noturno.money(biggest.value) : "R$ •••").moneyFont(28)
            }
        }.nightCard()
    }
}
#if DEBUG
#Preview("Noturno+ · 3 meses") { ExpenseReportViewTabs(report: .stressPreview) }
#Preview("Noturno+ · categorias") { ExpenseReportViewTabs(report: .stressPreview, initialRoute: .charts) }
#Preview("Noturno+ · timeline") { ExpenseReportViewTabs(report: .stressPreview, initialRoute: .allExpenses(nil, nil)) }
#Preview("Noturno+ · categoria") { ExpenseReportViewTabs(report: .stressPreview, initialRoute: .category("Supermercado")) }
#Preview("Noturno+ · estabelecimento") { ExpenseReportViewTabs(report: .stressPreview, initialRoute: .merchant("Uber")) }
#Preview("Noturno+ · Moradia · texto ampliado") {
    ExpenseReportViewTabs(report: .stressPreview, initialRoute: .category("Moradia / Contas"))
        .environment(\.dynamicTypeSize, .accessibility3)
}
#Preview("Noturno+ · despesa") {
    ExpenseReportViewTabs(report: .stressPreview, initialRoute: .expense(0))
}
#Preview("Noturno+ · período curto") { ExpenseReportViewTabs(report: .preview) }
#endif
