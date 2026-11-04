import Foundation

@main struct ExpenseEditingChecks {
    @MainActor static func main() async throws {
        func require(_ condition: @autoclosure () -> Bool, _ message: String) {
            precondition(condition(), message)
        }
        func response(_ expenses: [DetailedExpense]) -> ExpenseResponse {
            ExpenseResponse(SmartGroupExpenselist: [], AllExpenses: expenses, sessionToken: "report-test",
                            BiggestSingularExpense: nil, NotableDays: [], ExpensesByCategory: [])
        }
        func row(_ id: Int64, category: String = "Supermercado", value: Double = 10, date: String = "01/08/2026") -> DetailedExpense {
            DetailedExpense(expenseName: "Loja", value: value, date: date, category: category, expenseId: id)
        }
        let v2 = Data(#"{"reportId":"report-test","createdAt":"2026-08-01T12:00:00Z","expenses":[{"expenseId":42,"expenseName":"Loja","amount":12.5,"date":"2026-08-01","category":"Supermercado","categorySource":"FUTURE","source":"MANUAL"}],"expenseGroups":[],"categorySummaries":[],"highlights":null}"#.utf8)
        let decoded = try JSONDecoder().decode(ExpenseResponse.self, from: v2)
        require(decoded.AllExpenses[0].expenseId == 42, "server ID must survive decoding")
        require(decoded.AllExpenses[0].date == "01/08/2026", "ISO date maps to display date")
        require(decoded.AllExpenses[0].categorySource == "FUTURE", "unknown provenance remains compatible")
        let state = ExpenseReportState()
        await state.load(response([row(1), row(2), row(3, date: "01/09/2026")]))
        let ids = state.prepared!.all.expenses.map(\.id)
        require(Set(ids).count == 3, "identical transactions must have distinct IDs")
        state.month = YearMonth(NightDates.parse("01/09/2026")!)
        try await state.update { reportID in
            require(reportID == "report-test", "edit uses loaded report ID")
            require(state.isSaving, "saving remains true throughout operation")
            return response([row(1, category: "Transporte / Auto"), row(2, category: "Transporte / Auto"), row(3, category: "Transporte / Auto", date: "01/09/2026")])
        }
        require(!state.isSaving, "saving clears after success")
        require(state.prepared!.all.categories.first?.name == "Transporte / Auto", "category aggregates refresh")
        require(state.count(named: "Loja") == 3, "category count includes all months")
        require(state.current!.expenses.count == 1, "month filter stays selected")
        try await state.update { _ in response([row(2), row(3, date: "01/09/2026")]) }
        require(state.expense(ids[0]) == nil, "deleted route must not point to the next expense")
        require(state.expense(ids[1])?.expenseId == 2, "surviving ID remains stable after deletion")
        require(state.prepared!.all.total == 20, "delete recomputes total")
        try await state.update { _ in response([row(2), row(3, date: "01/09/2026"), row(4, value: 25)]) }
        require(state.prepared!.all.total == 45, "add recomputes total")
        require(state.prepared!.all.days.first?.count == 2, "calendar day count refreshes")
        require(state.prepared!.all.merchants.first?.count == 3, "merchant count refreshes")
        enum Failed: Error { case request }
        let revision = state.revision
        do {
            try await state.update { _ in throw Failed.request }
            preconditionFailure("failure must propagate")
        } catch Failed.request {}
        require(state.report!.AllExpenses.count == 3 && state.prepared!.all.total == 45, "failure preserves report")
        require(!state.isSaving && state.revision == revision, "failure clears progress without publishing changes")
        try await state.update { _ in response([row(2)]) }
        require(state.month == nil, "removed month resets filter")
        try await state.update { _ in response([]) }
        require(state.prepared!.all.total == 0 && state.prepared!.all.days.isEmpty, "last deletion yields empty report")
        for invalid in ["", "0", "-1", "12.50", "1,234", "1.23,45", "abc", "12,50xyz"] {
            require(ManualExpenseInput.amount(invalid) == nil, "reject invalid BRL: \(invalid)")
        }
        require(ManualExpenseInput.amount("1.234,56") == Decimal(string: "1234.56"), "BRL grouping")
        require(ManualExpenseInput.amount(" 42,50 ") == Decimal(string: "42.50"), "BRL decimals")
        require(ManualExpenseInput.date(Date(timeIntervalSince1970: 1785672000)).count == 10, "date serializes as yyyy-MM-dd")
        print("PASS: v2 decoding, duplicate IDs, category/delete/add, month filters, derived totals/calendar/merchants, failure preservation, empty report, BRL input")
    }
}
