//
//  ExpenseReportView.swift
//  extReader
//
//  Created by Renato Dias on 25/06/25.
//
import SwiftUI
import Charts

struct ExpenseReportView: View {
    @State var report: ExpenseResponse
    @State private var isLoading = false
    @State private var showErrorAlert = false
            
    var body: some View {
        ZStack {
            BackgroundView()
            ScrollView {
                    VStack {
                        if(report.AllExpenses.contains(where:    { $0.category == "" })){
                            HStack{
                                Text("Despesas não categorizadas totalmente!")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.yellow)
                                    .cornerRadius(0)
                                    .shadow(radius: 4)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                    .zIndex(1)
                            }
                        }
                        Divider()
                        CategoryChartView(report: report)
                            .scaledToFit()
                            .padding(.bottom)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.secondarySystemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                            )
                        Divider()
                        NavigationLink (destination: ExpenseDetailView(expense: report.BiggestSingularExpense)) {
                            BiggestExpenseView(expense: report.BiggestSingularExpense)
                        }
                        //Divider()
                        //TopExpensesView(expenses: (report.Top10Expenses))
                        ExpenseHighlightsView()
                        Divider()
                        ExpensesView(groupedList: report.SmartGroupExpenselist, allExpenses: report.AllExpenses)

                    }
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .navigationTitle("Relatório \(report.sessionToken)")
            .alert("Error", isPresented: $showErrorAlert) {
                                Button("OK", role: .cancel) {}
            }
            message: {
                    Text("Houve um erro na comunicação com o servidor.")
            }
            .refreshable {
                            await refreshData()
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
    ExpenseReportView(report: mock)
}
