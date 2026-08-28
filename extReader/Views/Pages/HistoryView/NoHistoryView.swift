//
//  NoHistoryView.swift
//  extReader
//
//  Created by Renato Dias on 09/09/25.
//
import SwiftUI

struct NoHistoryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("01")
                .font(.system(.title2, design: .monospaced).weight(.bold))
                .foregroundColor(.green)
            Text("Seus relatórios processados aparecerão aqui.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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
    NoHistoryView()
}
