//
//  ExpenseReportViewTabs.swift
//  extReader
//
//  Created by Renato Dias on 26/11/25.
//
import SwiftUI

struct ExpenseReportViewTabs: View {
    @State var report: ExpenseResponse
    @State private var isLoading = false
    @State private var showErrorAlert = false
            
    var body: some View {
        let busiestDay = report.NotableDays.sorted{$0.transactions > $1.transactions}.first
        let expensiveDay = report.NotableDays.sorted{$0.total > $1.total}.first
        let recurringExpense = report.SmartGroupExpenselist.sorted{$0.instances > $1.instances}.first
        var showWarning = report.AllExpenses.contains(where:    { $0.category == "" })
        ZStack {
            BackgroundView()
            if(showWarning){
                HStack{
                    Text("Despesas não categorizadas totalmente!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow.opacity(0.5))
                        .cornerRadius(0)
                        .shadow(radius: 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                        .onTapGesture {
                            showWarning = false
                        }
                }
            }
            TabView {
                CategoryChartView(report: report)
                    
                if((busiestDay != nil) && (expensiveDay != nil) && (recurringExpense != nil))
                {
                    ExpenseDashboardView(report: report)
                }
                
                ExpensesView(groupedList: report.SmartGroupExpenselist, allExpenses: report.AllExpenses)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page)
            .ignoresSafeArea()
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .navigationTitle("Relatório \(report.sessionToken)")
            .alert("Error", isPresented: $showErrorAlert) {
                                Button("OK", role: .cancel) {}
            }
            message: {
                    Text("Houve um erro na comunicação com o servidor.")
            }
        }
    }
    
    func refreshData() async {
        isLoading = true
        do {
            let res = try await ExpenseService.shared.fetchExpenses(sessionId: report.sessionToken)
            DispatchQueue.main.async {
                self.report = res
            }
        } catch {
            DispatchQueue.main.async {
                print("Deu Error: \(error.localizedDescription)")
                self.showErrorAlert = true
            }
        }
        isLoading = false
    }
}

#Preview {
    let mock = Bundle.main.decode(ExpenseResponse.self, from: "FakeReport.json")
    ExpenseReportViewTabs(report: mock)
}
