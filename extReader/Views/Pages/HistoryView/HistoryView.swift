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
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                }
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

#Preview {
    HistoryView(onSuccess: {_ in })
}
