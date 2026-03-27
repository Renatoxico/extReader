//
//  HistoryHeaderView.swift
//  extReader
//
//  Created by Renato Dias on 26/11/25.
//

import SwiftUI

struct HistoryHeaderView: View {
    var onSuccess: (ExpenseResponse) -> Void
    var body: some View {
        VStack(spacing: 4) {
            Text("Histórico de Sessões")
                .font(.title2.weight(.semibold))
                .foregroundColor(.green)
            Text("Pesquise ou consulte sessões anteriores")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HistorySearchView(onSuccess: onSuccess)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.black.opacity(0.4))
        .overlay(Divider().background(Color.green.opacity(0.3)), alignment: .bottom)
    }
}
