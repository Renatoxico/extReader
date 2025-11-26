//
//  StatCard.swift
//  extReader
//
//  Created by Renato Dias on 22/11/25.
//
import SwiftUI

struct StatCard: View {
    let title: String
    let mainValue: String
    let subValue: String
    let icon: String
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon Header
            HStack {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                Spacer()
                
                // Tiny arrow to indicate tappability
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(accentColor)
            }
            
            Spacer()
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(mainValue)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    // Allow text to shrink slightly if card is small
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text(subValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(height: 160) // Fixed height for uniformity
        .background(Color(.secondarySystemGroupedBackground)) // Pure white in light mode, dark gray in dark
        .cornerRadius(20)
        // Subtle shadow for "Pop"
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    StatCard(
        title: "Biggest Purchase",
        mainValue: "$2,499",
        subValue: "Apple Store",
        icon: "crown.fill",
        accentColor: .orange
    )
}
