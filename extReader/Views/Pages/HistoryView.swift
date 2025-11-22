//
//  HistoryView.swift
//  extReader
//
//  Created by Renato Dias on 09/09/25.
//
import SwiftUI

struct HistoryView: View {
    var onSuccess: (ExpenseResponse) -> Void
    @State private var history = UserDefaults.standard.stringArray(forKey: "historyItems") ?? []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
            BackgroundView()
            
            NavigationStack {
                VStack(spacing: 0) {
                    // MARK: Header
                    VStack(spacing: 4) {
                        Text("Histórico de Sessões")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.green)
                        Text("Pesquise ou consulte sessões anteriores")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.black.opacity(0.4))
                    .overlay(Divider().background(Color.green.opacity(0.3)), alignment: .bottom)
                    
                    if history.isEmpty {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 50))
                                .foregroundColor(.green.opacity(0.7))
                            Text("Nenhum histórico ainda")
                                .foregroundColor(.secondary)
                                .font(.headline)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(history.reversed(), id: \.self) { item in
                                HStack {
//                                    Image(systemName: "doc.text.magnifyingglass")
//                                        .foregroundColor(.green.opacity(0.8))
//                                        .font(.system(size: 20))
//                                    Text(item)
//                                        .font(.system(size: 16, weight: .medium))
//                                        .foregroundColor(.white)
                                    
                                    HistoryItemView(sessionId: item)
                                }
                                .padding(.vertical, 8)
                                .listRowBackground(Color.black.opacity(0.25))
                                .onTapGesture {
                                    Task {
                                        isLoading = true
                                        await getSessionData(item)
                                        isLoading = false
                                    }
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        if !history.isEmpty {
                            Button(action: {
                                UserDefaults.standard.removeObject(forKey: "historyItems")
                                withAnimation { history = [] }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red.opacity(0.85))
                            }
                        }
                    }
                }
                .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    history = UserDefaults.standard.stringArray(forKey: "historyItems") ?? []
                }
                .alert("Erro", isPresented: $showErrorAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Houve um erro na comunicação com o servidor.")
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
            let res = try await
                ExpenseService.shared.fetchExpenses(sessionId: sessionId)
            onSuccess(res)
        } catch{
            errorMessage = error.localizedDescription
            showErrorAlert = true
            print("Deu Error: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
}
