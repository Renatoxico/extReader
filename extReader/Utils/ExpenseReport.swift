//
//  ExpenseReport.swift
//  extReader
//
//  Created by Renato Dias on 03/06/25.
//

import Foundation

struct ExpenseResponse: Codable {
    let SmartGroupExpenselist: [GroupedExpense]
    let AllExpenses: [DetailedExpense]
    let sessionToken: String
    let BiggestSingularExpense: DetailedExpense?
    let NotableDays: [NotableDay]
    let ExpensesByCategory: [TotalByCategory]
}

struct GroupedExpense: Codable, Identifiable, Hashable {
    var id: String { expenseName }
    let expenseName: String
    let total: Double
    let instances: Int
    let category: String
}

struct TotalByCategory: Codable, Identifiable, Hashable {
    var id: String { category }
    let category: String
    let value: Double
}

struct NotableDay: Codable, Identifiable {
    var id: String { date }
    let date: String
    let total: Double
    let transactions: Int
}

struct DetailedExpense: Codable, Identifiable, Hashable {
    var id: String { "\(expenseName)-\(date)-\(value)" }
    let expenseName: String
    let value: Double
    let date: String
    let category: String?
    
    var formattedDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "pt_BR") // Assuming Brazilian Portuguese format
        return formatter.date(from: date) ?? Date()
    }
     static let mock = DetailedExpense(
              expenseName: "PIX ENVIADO Luciano Fabricio Rezende",
              value: 1503.54,
              date: "10/09/2025",
              category: "Outros / Transferências"
          )
}
