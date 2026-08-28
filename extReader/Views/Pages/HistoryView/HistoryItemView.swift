//
//  HistoryItemView.swift
//  extReader
//
//  Created by Renato Dias on 21/11/25.
//


import SwiftUI

struct HistoryItemView: View {
    let report: ReportSummary
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(report.formattedTotal)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer(minLength: 12)

                Text(report.formattedCreatedAt)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(report.shortId)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.8))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 12)

                Text(report.formattedCount)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            if isLoading {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(.green)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isLoading ? Color.green.opacity(0.28) : Color.clear)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
