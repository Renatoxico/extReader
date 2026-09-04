//
//  ExpenseReportViewTabs.swift
//  extReader
//
//  Created by Renato Dias on 26/11/25.
//
import SwiftUI

struct ExpenseReportViewTabs: View {
    @State var report: ExpenseResponse
    @State private var isExporting = false
    @State private var exportedCSVURL: URL? = nil
    @State private var showShareSheet = false
    @State private var showExportError = false
    @State private var dismissedWarningSignature: String? = nil

    var body: some View {
        let busiestDay = report.NotableDays.sorted{$0.transactions > $1.transactions}.first
        let expensiveDay = report.NotableDays.sorted{$0.total > $1.total}.first
        let recurringExpense = report.SmartGroupExpenselist.sorted{$0.instances > $1.instances}.first
        let warningSignature = uncategorizedWarningSignature
        let showWarning = !warningSignature.isEmpty && dismissedWarningSignature != warningSignature
        ZStack {
            BackgroundView()
            if(showWarning){
                HStack(spacing: 12) {
                    Text("Despesas não categorizadas totalmente!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        dismissedWarningSignature = warningSignature
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Dispensar aviso")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.yellow.opacity(0.5))
                .cornerRadius(0)
                .shadow(radius: 4)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
                        }
            TabView {
                CategoryChartViewDG(report: report)

                if((busiestDay != nil) && (expensiveDay != nil) && (recurringExpense != nil))
                {
                    ExpenseDashboardView(report: report)
                }

                ExpensesView(groupedList: report.SmartGroupExpenselist, allExpenses: report.AllExpenses)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page)
            .frame(maxWidth: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await exportCSV() }
                } label: {
                    if isExporting {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .disabled(isExporting)
            }
        }
        .sheet(isPresented: $showShareSheet, onDismiss: {
            if let url = exportedCSVURL {
                try? FileManager.default.removeItem(at: url)
                exportedCSVURL = nil
            }
        }) {
            if let url = exportedCSVURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Erro", isPresented: $showExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Não foi possível exportar o relatório.")
        }
    }

    private func exportCSV() async {
        isExporting = true
        do {
            let csvData = try await ExpenseService.shared.exportCSV(sessionId: report.sessionToken)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("despesas_\(report.sessionToken).csv")
            try csvData.write(to: tempURL)
            exportedCSVURL = tempURL
            showShareSheet = true
        } catch {
            showExportError = true
        }
        isExporting = false
    }

    private var uncategorizedWarningSignature: String {
        let uncategorizedExpenses = report.AllExpenses.filter { expense in
            expense.category?.isEmpty ?? true
        }

        guard !uncategorizedExpenses.isEmpty else { return "" }

        return ([report.sessionToken] + uncategorizedExpenses.map {
            "\($0.expenseName)|\($0.date)|\($0.value)"
        }).joined(separator: "#")
    }
}

#if DEBUG
#Preview {
    ExpenseReportViewTabs(report: .preview)
}
#endif
