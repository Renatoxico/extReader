//
//  StatisticsCardView.swift
//  extReader
//
//  Created by Renato Dias on 22/11/25.
//


import SwiftUI

struct StatisticsCardView: View {
    var body: some View {
        // The main container for the card
        VStack(alignment: .leading) {
            // MARK: - Card Header
            Text("📊 Expense Report Snapshot")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            // Separator Line
            Divider()
                .padding(.vertical, 4)
            
            // MARK: - Statistics Content
            VStack(spacing: 16) {
                // Statistic 1: Day with Most Transactions
                StatisticRowView(
                    title: "Day with Most Transactions",
                    value: "Tuesday, Nov 12",
                    iconName: "list.number"
                )
                
                // Statistic 2: Most Expensive Day
                StatisticRowView(
                    title: "Most Expensive Day",
                    value: "$1,250.50",
                    iconName: "dollarsign.circle.fill",
                    valueColor: Color.red // Highlight expensive day
                )
            }
            .padding(.top, 8)
            
            // MARK: - Footer (Optional)
            Text("Data for the current period")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 10)
        }
        .padding(20) // Internal padding for the card content
        .background(Color(.systemGray6)) // Light background for the card
        .cornerRadius(15) // Rounded corners
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2) // Subtle shadow for depth
        //.padding(.horizontal) // External padding to keep it off the screen edges
    }
}

// MARK: - Reusable Row View for a Single Statistic

struct StatisticRowView: View {
    let title: String
    let value: String
    let iconName: String
    var valueColor: Color = .primary // Default value color
    
    var body: some View {
        HStack {
            // Icon
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.blue) // A strong accent color for the icon
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                // Title (Description)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Value (The actual statistic)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(valueColor)
            }
            
            Spacer() // Pushes everything to the left
        }
    }
}

 //To preview the card:
 struct StatisticsCardView_Previews: PreviewProvider {
     static var previews: some View {
         StatisticsCardView()
     }
 }
