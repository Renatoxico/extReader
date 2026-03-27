//
//  HistorySearchView.swift
//  extReader
//
//  Created by Renato Dias on 28/11/25.
//

import SwiftUI

struct HistorySearchView: View {
    var onSuccess: (ExpenseResponse) -> Void
    @State private var sessionId = ""
    @State private var isLoading = false
    @State private var showErrorAlert = false
    
    var body: some View {
        HStack {
            BeautifulTextField(
                title: "",
                iconName: "magnifyingglass",
                text: $sessionId
            )
            if sessionId.count > 0 {
                Button {
                    Task {
                        await getSessionData(sessionId)
                    }
                } label: {
                    HStack{
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    )
                    .shadow(color: .green.opacity(0.4), radius: 10, y: 4)
                }
                .disabled(isLoading)
                .padding()
                .padding(.top, 12)
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
            SessionHistoryService.shared.add(res.sessionToken)
        } catch{
            print("Deu Error: \(error.localizedDescription)")
            showErrorAlert = true
        }
        isLoading = false
    }
    
}
