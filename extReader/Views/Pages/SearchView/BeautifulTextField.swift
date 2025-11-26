//
//  BeautifulTextField.swift
//  extReader
//
//  Created by Renato Dias on 07/06/25.
//


import SwiftUI

struct BeautifulTextField: View {
    let title: String
    let iconName: String?
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
            
            // TextField container
            HStack {
                // Icon if provided
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(.gray)
                        .frame(width: 20)
                }
                
                // Actual text input
                Group {
                    if isSecure {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .textFieldStyle(.plain)
                .font(.body)
                .tint(.blue) // Cursor color
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}