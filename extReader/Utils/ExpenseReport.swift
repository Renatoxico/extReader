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
    let BiggestSingularExpense: DetailedExpense
    let NotableDays: [NotableDay]
    let ExpensesByCategory: [TotalByCategory]
}

struct GroupedExpense: Codable, Identifiable {
    let id = UUID()
    let expenseName: String
    let total: Double
    let instances: Int
    let category: String
    
    // Required for Codable to ignore the id property
    enum CodingKeys: CodingKey {
        case expenseName, total, instances, category
    }
}

struct TotalByCategory: Codable, Identifiable {
    let id = UUID()
    let category: String
    let value: Double
    
    enum CodingKeys: CodingKey {
        case category, value
    }
}

struct NotableDay: Codable, Identifiable {
    let id = UUID()
    let date: String
    let total: Double
    let transactions: Int
    
    enum CodingKeys: CodingKey {
        case date, total, transactions
    }
}

struct DetailedExpense: Codable, Identifiable {
    let id = UUID()
    let expenseName: String
    let value: Double
    let date: String
    let category: String?
    
    enum CodingKeys: CodingKey {
        case expenseName, value, date, category
    }
    
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
