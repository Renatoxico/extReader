//
//  HistoryView.swift
//  extReader
//
//  Created by Renato Dias on 09/09/25.
//
import SwiftUI

struct HistoryView: View {
    var onSuccess: (ExpenseResponse) -> Void
    @State private var history = SessionHistoryService.shared.allItems()
    @State private var isLoading = false
    @State private var showErrorAlert = false
    @State private var exportedCSVURL: URL? = nil
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            BackgroundView()

            NavigationStack {
                VStack(spacing: 0) {
                    HistoryHeaderView(onSuccess: onSuccess)
                    if history.isEmpty {
                        Spacer()
                        NoHistoryView()
                        Spacer()
                        Spacer()
                    } else {
                        List {
                            ForEach(history.reversed(), id: \.self) { item in
                                HStack {
                                    HistoryItemView(sessionId: item)
                                        .onTapGesture {
                                            Task {
                                                isLoading = true
                                                await getSessionData(item)
                                                isLoading = false
                                            }
                                        }
                                    Spacer()
                                    DeleteButtonView(sessionId: item)
                                }
                                .padding(.vertical, 8)
                                .listRowBackground(Color.black.opacity(0.25))
                                .swipeActions(edge: .leading) {
                                    Button {
                                        Task { await exportSession(item) }
                                    } label: {
                                        Label("Exportar", systemImage: "square.and.arrow.up")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                }
                .onAppear {
                    history = SessionHistoryService.shared.allItems()
                }
                .alert("Erro", isPresented: $showErrorAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Houve um erro na comunicação com o servidor.")
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
            }

            if isLoading {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView("Carregando...")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.green)
                    .cornerRadius(12)
            }
        }
    }

    func getSessionData(_ sessionId: String) async {
        isLoading = true
        do {
            let res = try await ExpenseService.shared.fetchExpenses(sessionId: sessionId)
            onSuccess(res)
        } catch {
            showErrorAlert = true
        }
        isLoading = false
    }

    func exportSession(_ sessionId: String) async {
        isLoading = true
        do {
            let csvData = try await ExpenseService.shared.exportCSV(sessionId: sessionId)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("despesas_\(sessionId).csv")
            try csvData.write(to: tempURL)
            exportedCSVURL = tempURL
            showShareSheet = true
        } catch {
            showErrorAlert = true
        }
        isLoading = false
    }
}

#Preview {
    HistoryView(onSuccess: {_ in })
}
