//
//  HistoryView.swift
//  extReader
//
//  Created by Renato Dias on 09/09/25.
//
import SwiftUI

struct HistoryView: View {
    var onSuccess: (ExpenseResponse) -> Void
    @State private var reports: [ReportSummary] = []
    @State private var isLoadingReports = false
    @State private var loadingReportId: String?
    @State private var showErrorAlert = false
    @State private var loadErrorMessage: String?
    @State private var errorMessage = "Houve um erro na comunicação com o servidor."

    var body: some View {
        ZStack {
            BackgroundView()

            NavigationStack {
                VStack(spacing: 0) {
                    HistoryHeaderView()

                    if isLoadingReports && reports.isEmpty {
                        Spacer()
                        ProgressView("Carregando histórico...")
                            .tint(.green)
                            .foregroundColor(.secondary)
                        Spacer()
                    } else if let loadErrorMessage, reports.isEmpty {
                        HistoryErrorView(message: loadErrorMessage) {
                            Task { await loadReports() }
                        }
                        Spacer()
                    } else if reports.isEmpty {
                        NoHistoryView()
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(reports) { report in
                                    Button {
                                        Task { await getReportData(report.reportId) }
                                    } label: {
                                        HistoryItemView(
                                            report: report,
                                            isLoading: loadingReportId == report.reportId
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(loadingReportId != nil)
                                }
                            }
                            .padding(12)
                        }
                        .background(Color(red: 17/255, green: 20/255, blue: 26/255))
                        .refreshable {
                            await loadReports()
                        }
                    }
                }
                .onAppear {
                    Task { await loadReports() }
                }
                .alert("Erro", isPresented: $showErrorAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage)
                }
            }

            if loadingReportId != nil {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView("Carregando...")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.green)
                    .cornerRadius(12)
            }
        }
    }

    func loadReports() async {
        guard !isLoadingReports else { return }

        isLoadingReports = true
        do {
            reports = try await ExpenseService.shared.fetchReports()
            loadErrorMessage = nil
        } catch {
            loadErrorMessage = error.localizedDescription
        }
        isLoadingReports = false
    }

    func getReportData(_ reportId: String) async {
        loadingReportId = reportId
        do {
            let res = try await ExpenseService.shared.fetchExpenses(sessionId: reportId)
            onSuccess(res)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        loadingReportId = nil
    }
}

private struct HistoryErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onRetry) {
                Text("Tentar novamente")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.white.opacity(0.10), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        )
        .padding(16)
    }
}

#Preview {
    HistoryView(onSuccess: {_ in })
}
