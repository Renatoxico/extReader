//
//  HistoryItemView.swift
//  extReader
//
//  Created by Renato Dias on 21/11/25.
//


import SwiftUI

struct HistoryItemView: View {
    let sessionId: String

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
        }
        .padding(.vertical, 6)
    }
    
    
}

