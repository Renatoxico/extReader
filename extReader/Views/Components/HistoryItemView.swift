//
//  HistoryItemView.swift
//  extReader
//
//  Created by Renato Dias on 21/11/25.
//


import SwiftUI

struct HistoryItemView: View {
    let sessionId: String
//    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(.blue)
                .font(.system(size: 20))

            Text(sessionId)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

                Image(systemName: "trash")
                    .foregroundColor(.red)
           
        }
        .padding(.vertical, 6)
    }
    
    func deleteSession(_ sessionId: String) {
        var history = UserDefaults.standard.stringArray(forKey: "historyItems") ?? []
        history.removeAll { $0 == sessionId }
        UserDefaults.standard.set(history, forKey: "historyItems")
    }
}

