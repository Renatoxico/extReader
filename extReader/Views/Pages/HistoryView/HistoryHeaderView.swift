//
//  HistoryHeaderView.swift
//  extReader
//
//  Created by Renato Dias on 26/11/25.
//

import SwiftUI

struct HistoryHeaderView: View {
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sua biblioteca")
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundColor(.green)
                Text("Relatórios")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(Color(red: 17/255, green: 20/255, blue: 26/255))
        .overlay(Divider().background(Color.white.opacity(0.06)), alignment: .bottom)
    }
}
