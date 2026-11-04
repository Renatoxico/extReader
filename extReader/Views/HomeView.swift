import SwiftUI

struct HomeView: View {
    @State private var expenses: ExpenseResponse?
    @SceneStorage("selectedTab") private var selectedTab = 1
    private func openReport(_ result: ExpenseResponse) { expenses = result; selectedTab = 3 }
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { UploadExpenseView(onSuccess: openReport) }
                .tabItem { Label("Enviar", systemImage: "arrow.up.doc") }.tag(1)
            HistoryView(onSuccess: openReport)
                .tabItem { Label("Histórico", systemImage: "clock.arrow.circlepath") }.tag(2)
            Group {
                if let expenses { ExpenseReportViewTabs(report: expenses).id(expenses.sessionToken) }
                else {
                    ContentUnavailableView("Seu relatório", systemImage: "chart.bar", description: Text("Envie um comprovante ou abra um relatório no Histórico."))
                        .background { BackgroundView() }
                }
            }.tabItem { Label("Relatório", systemImage: "chart.bar") }.tag(3)
            NavigationStack { AccountView() }
                .tabItem { Label("Conta", systemImage: "person.crop.circle") }.tag(4)
        }.tint(Noturno.emerald).preferredColorScheme(.dark)
    }
}
#Preview { HomeView() }
