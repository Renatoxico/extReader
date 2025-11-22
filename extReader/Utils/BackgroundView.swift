//
//  BackgroundView.swift
//  extReader
//
//  Created by Renato Dias on 30/10/25.
//

import SwiftUI

public struct BackgroundView: View {
    public var body: some View {
        LinearGradient(
                        colors: [
                            Color.black,
                            Color(red: 0.02, green: 0.1, blue: 0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
    }
}
