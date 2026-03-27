//
//  DeleteButtonView.swift
//  extReader
//
//  Created by Renato Dias on 28/11/25.
//

import SwiftUI

struct DeleteButtonView: View {
    let sessionId: String
    @State var isPresented: Bool = false
    var body: some View {
        Button{
            isPresented = true
        }
        label: {
            Image(systemName: "trash")
                .foregroundColor(.red)
        }
            .confirmationDialog(
                "Are you sure?",
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteSession(sessionId)
                }
                Button("Cancel", role: .cancel) { }
            }
    }
    
    func deleteSession(_ sessionId: String) {
        SessionHistoryService.shared.delete(sessionId)
    }
}
