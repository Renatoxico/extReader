import Foundation
import Combine

typealias NightReportStore = ExpenseReportState

@MainActor final class ExpenseReportState: ObservableObject {
    @Published private(set) var report: ExpenseResponse?
    @Published private(set) var isSaving = false
    @Published private(set) var revision = 0
    private var stableIDs: [String: Int] = [:]
    private var nextID = 0
    private var originals: [Int: DetailedExpense] = [:]
    func expense(_ id: Int) -> DetailedExpense? { originals[id] }
    func count(named name: String) -> Int { report?.AllExpenses.filter { $0.expenseName == name }.count ?? 0 }
    func update(_ operation: (String) async throws -> ExpenseResponse) async throws {
        guard let report, !isSaving else { throw ExpenseService.NetworkError.serverError("Aguarde o relatório terminar de salvar.") }
        isSaving = true
        defer { isSaving = false }
        let updated = try await operation(report.sessionToken)
        await load(updated)
    }
    static func message(for error: Error) -> String {
        if case ExpenseService.NetworkError.serverError(let message) = error { return message }
        if error is URLError { return "Não foi possível conectar. Verifique sua internet e tente novamente." }
        return "Não foi possível salvar. Confira sua conexão e sua sessão e tente novamente."
    }
    @Published var prepared: PreparedReport?
    @Published var month: YearMonth?
    @Published var path: [ReportRoute] = []
    @Published var selectedDay: SelectedNightDay?
    @Published var focusDay: Date?
    @Published var highlightedDay: Date?
    @Published var feedback = 0
    var current: FilteredReport? { month.flatMap { prepared?.filtered[$0] } ?? prepared?.all }
    func openDay(_ date: Date) { selectedDay = SelectedNightDay(id: date); highlightedDay = date; feedback += 1 }
    func push(_ route: ReportRoute) { path.append(route); feedback += 1 }
    func load(_ response: ExpenseResponse) async {
        var mapped: [Int: DetailedExpense] = [:]
        let rows = response.AllExpenses.enumerated().compactMap { index, expense -> NightExpense? in
            guard let date = NightDates.parse(expense.date) else { return nil }
            let category = expense.category?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let key = expense.expenseId.map { "server-\($0)" } ?? "legacy-\(index)-\(expense.id)"
            let id: Int
            if let existing = stableIDs[key] { id = existing }
            else { id = nextID; nextID += 1; stableIDs[key] = id }
            mapped[id] = expense
            return NightExpense(id: id, name: expense.expenseName, date: date, value: expense.value, category: category.isEmpty ? "Outros / Transferências" : category)
        }
        let summaries = response.ExpensesByCategory.reduce(into: [String: Double]()) { result, cat in
            let name = cat.category.trimmingCharacters(in: .whitespacesAndNewlines)
            result[name.isEmpty ? "Outros / Transferências" : name, default: 0] += cat.value
        }
        let result = await Task.detached(priority: .userInitiated) { PreparedReport.prepare(expenses: rows, summaries: summaries) }.value
        report = response
        originals = mapped
        prepared = result
        if let month, !result.months.contains(month) { self.month = nil }
        revision += 1
    }
    func fromSheet(_ route: ReportRoute, focus: Date? = nil) {
        focusDay = focus
        selectedDay = nil
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            push(route)
        }
    }
}
