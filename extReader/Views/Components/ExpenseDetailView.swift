import SwiftUI

struct ExpenseDetailView: View {
    let expense: DetailedExpense
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                NightTile(category: expense.category ?? "Outros / Transferências")
                Text(expense.expenseName).font(.title2.bold())
                Text(Noturno.money(expense.value)).moneyFont(40)
                Divider()
                LabeledContent("Data", value: expense.date)
                LabeledContent("Categoria", value: expense.category ?? "Sem categoria")
                HStack {
                    if expense.source == "MANUAL" { Label("Manual", systemImage: "plus.circle") }
                    if expense.categorySource == "USER" { Label("Editado", systemImage: "pencil") }
                }.font(.caption).foregroundStyle(Noturno.secondary)
            }.nightCard()
                .modifier(NightExpenseActions(detail: expense, showButtons: true))
                .padding(20)
        }.background { NoturnoBackground(tint: .forCategory(expense.category ?? ""), top: true) }
            .navigationTitle("Detalhes da despesa").navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    ExpenseReportViewTabs(report: .preview, initialRoute: .expense(0))
}
#endif
