//
//  NoHistoryView.swift
//  extReader
//
//  Created by Renato Dias on 09/09/25.
//
import SwiftUI

struct NoHistoryView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 50))
                .foregroundColor(.green.opacity(0.7))
            Text("Nenhum histórico ainda")
                .foregroundColor(.secondary)
                .font(.headline)
        }
        .padding()
//        .frame(maxWidth: .infinity, minHeight: 150)
//        .background(
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color(.systemGray6))
//        )
    }
}

#Preview {
    NoHistoryView()
}
