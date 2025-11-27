//
//  ContentView.swift
//  extReader
//
//  Created by Renato Dias on 25/05/25.
//

import SwiftUI
import UIKit

struct HomeView: View {
    @State private var expenses: ExpenseResponse? = nil
    @State private var goToDetails = false
    @SceneStorage("selectedTab") private var selectedTab = 0
    var body: some View {
        NavigationStack{
            ZStack {
                Color(red: 0/255, green: 8/255, blue: 4/255)
                    .ignoresSafeArea()
                VStack {
                    
                    TabView(selection: $selectedTab) {
                        SearchSessionView{result in
                            self.expenses = result
                            self.goToDetails = true}
                            .environment(\.colorScheme, .dark)
                            .tabItem {
                                Label("Pesquisar", systemImage:"magnifyingglass")
                            }
                            .tag(0)
                        UploadExpenseView{result in
                            self.expenses = result
                            self.goToDetails = true}
                            .environment(\.colorScheme, .dark)
                            .tabItem {
                                Label("Enviar", systemImage: "house")
                            }
                            .tag(1)
                        HistoryView{result in
                            self.expenses = result
                            self.goToDetails = true}
                            .environment(\.colorScheme, .dark)
                            .tabItem {
                                Label("Histórico", systemImage: "clock")
                            }
                            .tag(2)
                    }.navigationDestination(isPresented: $goToDetails) {
                        if let expenses = expenses {
                            ExpenseReportViewTabs(report: expenses)
                        } else {
                            Text("No data") // fallback
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}

