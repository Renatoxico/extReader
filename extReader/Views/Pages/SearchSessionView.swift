//
//  SearchSessionView.swift
//  extReader
//
//  Created by Renato Dias on 07/06/25.
//

import SwiftUI

struct SearchSessionView: View {
    var onSuccess: (ExpenseResponse) -> Void
    @State private var sessionId = ""
    //@State private var expenses: ExpenseResponse? = nil
    @State private var isLoading = false
    //@State private var goToDetails = false
    @State private var showErrorAlert = false
    var body: some View {
        ZStack{
            BackgroundView()
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                    to: nil, from: nil, for: nil)
                }
            VStack(spacing: 40) {
                            // Logo
                            VStack(spacing: 12) {
                                Image("logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                                    //.shadow(color: .green.opacity(0.4), radius: 12, x: 0, y: 6)

                                Text("Buscar Relatórios")
                                    .font(.title2.bold())
                                    //.foregroundColor(.green.opacity(0.9))
                                    .tracking(0.5)
                            }
                            .padding(.top, 60)

                            // Search field
                            BeautifulTextField(
                                title: "Session ID",
                                iconName: "magnifyingglass",
                                text: $sessionId
                            )
                            .padding(.horizontal, 30)
                            .shadow(color: .green.opacity(0.25), radius: 8, y: 3)

                            // Button
                            if sessionId.count > 0 {
                                Button {
                                    Task {
                                        await getSessionData(sessionId)
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        if isLoading {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "magnifyingglass")
                                            Text("Consultar Sessão")
                                        }
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.green, Color.green.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    )
                                    .shadow(color: .green.opacity(0.4), radius: 10, y: 4)
                                    .padding(.horizontal, 50)
                                }
                                .disabled(isLoading)
                            }

                            Spacer()
                        }
            if isLoading {
            Color.black.opacity(0.4) // dim background
            .ignoresSafeArea()
            ProgressView("Loading...")
                .padding()
                .cornerRadius(10)
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
                            Button("OK", role: .cancel) {}
        }
        message: {
                Text("Houve um erro na comunicação com o servidor.")
        }
        
    }
    
    func getSessionData(_ sessionId: String) async {
        isLoading = true
        do {
            let res = try await
                ExpenseService.shared.fetchExpenses(sessionId: sessionId)
            onSuccess(res)
            addToHistory(res.sessionToken)
        } catch{
            print("Deu Error: \(error.localizedDescription)")
            showErrorAlert = true
        }
        isLoading = false
    }
    
    func addToHistory(_ newItem: String) {
        var history = UserDefaults.standard.stringArray(forKey: "historyItems") ?? []
        history.append(newItem)
        UserDefaults.standard.set(history, forKey: "historyItems")
    }
}
