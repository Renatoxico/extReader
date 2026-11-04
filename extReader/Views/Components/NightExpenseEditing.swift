import SwiftUI

extension View {
    func nightExpenseActions(_ expense: NightExpense) -> some View {
        modifier(NightExpenseActions(rowID: expense.id))
    }
}

struct NightExpenseActions: ViewModifier {
    var rowID: Int? = nil
    var detail: DetailedExpense? = nil
    var showButtons = false
    @EnvironmentObject private var state: ExpenseReportState
    @Environment(\.dismiss) private var dismiss
    @State private var changingCategory = false
    @State private var confirmingDelete = false
    @State private var deleting = false
    @State private var error: String?
    private var expense: DetailedExpense? {
        if let rowID { return state.expense(rowID) }
        if let id = detail?.expenseId { return state.report?.AllExpenses.first { $0.expenseId == id } }
        return detail
    }
    func body(content: Content) -> some View {
        VStack(spacing: 12) {
            content.contextMenu { actions }.accessibilityHint(showButtons ? "" : "Mantenha pressionado para alterar a categoria ou excluir")
            if deleting { ProgressView("Excluindo…").font(.caption) }
            if showButtons { actions.frame(maxWidth: .infinity, alignment: .leading).nightCard() }
        }
        .sheet(isPresented: $changingCategory) {
            if let expense { NightChangeCategoryView(expense: expense) }
        }
        .confirmationDialog("Excluir esta despesa?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Excluir", role: .destructive) {
                guard let id = expense?.expenseId else { return }
                Task {
                    deleting = true
                    defer { deleting = false }
                    do {
                        try await state.update { try await ExpenseService.shared.deleteExpense(reportId: $0, expenseId: id) }
                        if showButtons { dismiss() }
                    } catch { self.error = ExpenseReportState.message(for: error) }
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("A despesa será excluída permanentemente deste relatório. Essa ação não pode ser desfeita.")
        }
        .alert("Não foi possível salvar", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(error ?? "") }
    }
    @ViewBuilder private var actions: some View {
        if expense != nil {
            Button("Alterar categoria", systemImage: "tag") { changingCategory = true }.disabled(state.isSaving)
            Button("Excluir", systemImage: "trash", role: .destructive) { confirmingDelete = true }
                .disabled(state.isSaving || expense?.expenseId == nil)
            if showButtons, expense?.expenseId == nil {
                Text("Abra novamente o relatório para carregar o identificador necessário para excluir.")
                    .font(.caption).foregroundStyle(Noturno.secondary)
            }
        }
    }
}

private struct NightCategoryChoices: View {
    @Binding var selection: String
    var body: some View {
        VStack(spacing: 8) {
            ForEach(ExpenseCategories.all, id: \.self) { category in
                Button { selection = category } label: {
                    HStack(spacing: 12) {
                        NightTile(category: category)
                        Text(category).font(.subheadline).multilineTextAlignment(.leading)
                        Spacer(minLength: 4)
                        Image(systemName: selection == category ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selection == category ? Color.forCategory(category) : Noturno.tertiary)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
                        .background(Noturno.surface2, in: RoundedRectangle(cornerRadius: 16))
                }.accessibilityAddTraits(selection == category ? .isSelected : [])
            }
        }
    }
}

struct NightChangeCategoryView: View {
    let expense: DetailedExpense
    @EnvironmentObject private var state: ExpenseReportState
    @Environment(\.dismiss) private var dismiss
    @State private var category: String
    @State private var error: String?
    init(expense: DetailedExpense) {
        self.expense = expense
        _category = State(initialValue: expense.category ?? "")
    }
    var body: some View {
        NightEditingSheet(title: "Alterar categoria", saving: state.isSaving, error: $error) {
            VStack(alignment: .leading, spacing: 18) {
                Text(expense.expenseName).font(.title2.bold())
                Text("A nova categoria será aplicada a todas as despesas com este nome neste relatório: \(state.count(named: expense.expenseName)) lançamentos, incluindo outros meses.")
                    .font(.subheadline).foregroundStyle(Noturno.secondary)
                NightCategoryChoices(selection: $category)
                NightSaveButton(saving: state.isSaving, valid: ExpenseCategories.all.contains(category)) {
                    Task {
                        do {
                            try await state.update { try await ExpenseService.shared.changeCategory(reportId: $0, expenseName: expense.expenseName, newCategory: category) }
                            dismiss()
                        } catch { self.error = ExpenseReportState.message(for: error) }
                    }
                }
            }
        }
    }
}

struct NightAddExpenseView: View {
    @EnvironmentObject private var state: ExpenseReportState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var category = "Supermercado"
    @State private var error: String?
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var body: some View {
        NightEditingSheet(title: "Adicionar despesa", saving: state.isSaving, error: $error) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("DESPESA MANUAL").font(.caption.bold()).foregroundStyle(Noturno.emerald)
                    TextField("Descrição", text: $name).textInputAutocapitalization(.sentences).accessibilityLabel("Descrição")
                    Divider()
                    HStack {
                        Text("R$").foregroundStyle(Noturno.secondary)
                        TextField("0,00", text: $amount).keyboardType(.decimalPad).moneyFont(28).accessibilityLabel("Valor em reais")
                    }
                    Text("Ex.: 1.234,56 · valor maior que zero").font(.caption).foregroundStyle(Noturno.secondary)
                    DatePicker("Data", selection: $date, displayedComponents: .date)
                }.nightCard()
                Text("CATEGORIA").font(.caption.bold()).foregroundStyle(Noturno.secondary)
                NightCategoryChoices(selection: $category)
                NightSaveButton(saving: state.isSaving, valid: !trimmedName.isEmpty && ManualExpenseInput.amount(amount) != nil) {
                    guard let value = ManualExpenseInput.amount(amount) else { return }
                    Task {
                        do {
                            try await state.update {
                                try await ExpenseService.shared.addExpense(reportId: $0, name: trimmedName, amount: value, date: ManualExpenseInput.date(date), category: category)
                            }
                            // Show the new expense even when its date falls outside the selected month.
                            state.month = nil
                            dismiss()
                        } catch { self.error = ExpenseReportState.message(for: error) }
                    }
                }
            }
        }
    }
}

private struct NightSaveButton: View {
    let saving: Bool
    let valid: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                if saving { ProgressView().tint(.black) }
                Text(saving ? "Salvando…" : "Salvar").font(.headline)
                Spacer()
            }.padding(16).foregroundStyle(.black).background(Noturno.emerald, in: RoundedRectangle(cornerRadius: 16))
        }.disabled(!valid || saving).opacity(valid ? 1 : 0.45)
    }
}

private struct NightEditingSheet<Content: View>: View {
    let title: String
    let saving: Bool
    @Binding var error: String?
    @ViewBuilder let content: () -> Content
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView { content().padding(20).disabled(saving) }
                .scrollDismissesKeyboard(.interactively)
                .background { NoturnoBackground(tint: Noturno.emerald, top: true) }
                .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() }.disabled(saving) } }
                .alert("Não foi possível salvar", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                    Button("OK", role: .cancel) {}
                } message: { Text(error ?? "") }
        }.preferredColorScheme(.dark).tint(Noturno.emerald).foregroundStyle(Noturno.text)
            .environment(\.locale, Locale(identifier: "pt_BR"))
            .buttonStyle(NoturnoPress()).interactiveDismissDisabled(saving)
    }
}

#if DEBUG
private struct NightEditingPreview: View {
    var adding = false
    @StateObject private var state = ExpenseReportState()
    var body: some View {
        Group {
            if adding { NightAddExpenseView() }
            else { NightChangeCategoryView(expense: ExpenseResponse.preview.AllExpenses[0]) }
        }.environmentObject(state).task { await state.load(.preview) }
    }
}
#Preview("Noturno+ · adicionar despesa") { NightEditingPreview(adding: true) }
#Preview("Noturno+ · alterar categoria") { NightEditingPreview() }
#endif
