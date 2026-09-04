//
//  ExpenseReport.swift
//  extReader
//
//  Created by Renato Dias on 03/06/25.
//

import Foundation

struct ExpenseResponse: Decodable {
    let SmartGroupExpenselist: [GroupedExpense]
    let AllExpenses: [DetailedExpense]
    let sessionToken: String
    let BiggestSingularExpense: DetailedExpense?
    let NotableDays: [NotableDay]
    let ExpensesByCategory: [TotalByCategory]

    enum CodingKeys: String, CodingKey {
        case SmartGroupExpenselist
        case AllExpenses
        case sessionToken
        case BiggestSingularExpense
        case NotableDays
        case ExpensesByCategory
        case reportId
        case expenses
        case expenseGroups
        case categorySummaries
        case highlights
    }

    init(
        SmartGroupExpenselist: [GroupedExpense],
        AllExpenses: [DetailedExpense],
        sessionToken: String,
        BiggestSingularExpense: DetailedExpense?,
        NotableDays: [NotableDay],
        ExpensesByCategory: [TotalByCategory]
    ) {
        self.SmartGroupExpenselist = SmartGroupExpenselist
        self.AllExpenses = AllExpenses
        self.sessionToken = sessionToken
        self.BiggestSingularExpense = BiggestSingularExpense
        self.NotableDays = NotableDays
        self.ExpensesByCategory = ExpensesByCategory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.reportId) {
            let report = try ExpenseReport(from: decoder)
            self.sessionToken = report.reportId
            self.AllExpenses = report.expenses
            self.SmartGroupExpenselist = report.expenseGroups
            self.ExpensesByCategory = report.categorySummaries
            self.BiggestSingularExpense = report.highlights?.largestExpense
            self.NotableDays = [
                report.highlights?.mostActiveDay,
                report.highlights?.highestSpendingDay
            ].compactMap { $0 }
            return
        }

        self.SmartGroupExpenselist = try container.decode([GroupedExpense].self, forKey: .SmartGroupExpenselist)
        self.AllExpenses = try container.decode([DetailedExpense].self, forKey: .AllExpenses)
        self.sessionToken = try container.decode(String.self, forKey: .sessionToken)
        self.BiggestSingularExpense = try container.decodeIfPresent(DetailedExpense.self, forKey: .BiggestSingularExpense)
        self.NotableDays = try container.decode([NotableDay].self, forKey: .NotableDays)
        self.ExpensesByCategory = try container.decode([TotalByCategory].self, forKey: .ExpensesByCategory)
    }
}

private struct ExpenseReport: Decodable {
    let reportId: String
    let createdAt: String
    let expenses: [DetailedExpense]
    let expenseGroups: [GroupedExpense]
    let categorySummaries: [TotalByCategory]
    let highlights: ReportHighlights?
}

struct ReportSummary: Decodable, Identifiable {
    var id: String { reportId }

    let reportId: String
    let createdAt: String
    let total: Double
    let countExpenses: Int

    var formattedTotal: String {
        Self.currencyFormatter.string(from: NSNumber(value: total)) ?? "R$ \(String(format: "%.2f", total))"
    }

    var formattedCreatedAt: String {
        guard let date = Self.parseDate(createdAt) else { return createdAt }
        return Self.createdAtFormatter.string(from: date)
    }

    var formattedCount: String {
        countExpenses == 1 ? "1 transação" : "\(countExpenses) transações"
    }

    var shortId: String {
        guard reportId.count > 12 else { return reportId }
        return "\(reportId.prefix(8))...\(reportId.suffix(4))"
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        return formatter
    }()

    private static let createdAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }()

    private static func parseDate(_ value: String) -> Date? {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = fractionalFormatter.date(from: value) {
            return date
        }

        return ISO8601DateFormatter().date(from: value)
    }
}

private struct ReportHighlights: Decodable {
    let largestExpense: DetailedExpense?
    let mostActiveDay: NotableDay?
    let highestSpendingDay: NotableDay?
}

struct GroupedExpense: Decodable, Identifiable, Hashable {
    var id: String { expenseName }
    let expenseName: String
    let total: Double
    let instances: Int
    let category: String

    enum CodingKeys: String, CodingKey {
        case expenseName
        case total
        case instances
        case category
        case totalAmount
        case occurrenceCount
    }

    init(expenseName: String, total: Double, instances: Int, category: String) {
        self.expenseName = expenseName
        self.total = total
        self.instances = instances
        self.category = category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.expenseName = try container.decode(String.self, forKey: .expenseName)
        self.total = try container.decodeFlexibleDouble(primary: .total, fallback: .totalAmount)
        self.instances = try container.decodeFlexibleInt(primary: .instances, fallback: .occurrenceCount)
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
    }
}

struct TotalByCategory: Decodable, Identifiable, Hashable {
    var id: String { category }
    let category: String
    let value: Double

    enum CodingKeys: String, CodingKey {
        case category
        case value
        case totalAmount
    }

    init(category: String, value: Double) {
        self.category = category
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.category = try container.decode(String.self, forKey: .category)
        self.value = try container.decodeFlexibleDouble(primary: .value, fallback: .totalAmount)
    }
}

struct NotableDay: Decodable, Identifiable {
    var id: String { date }
    let date: String
    let total: Double
    let transactions: Int

    enum CodingKeys: String, CodingKey {
        case date
        case total
        case transactions
        case totalAmount
        case transactionCount
    }

    init(date: String, total: Double, transactions: Int) {
        self.date = date
        self.total = total
        self.transactions = transactions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.date = Self.displayDate(from: try container.decode(String.self, forKey: .date))
        self.total = try container.decodeFlexibleDouble(primary: .total, fallback: .totalAmount)
        self.transactions = try container.decodeFlexibleInt(primary: .transactions, fallback: .transactionCount)
    }

    private static func displayDate(from rawValue: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.locale = Locale(identifier: "pt_BR")
        inputFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = inputFormatter.date(from: rawValue) else { return rawValue }

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "pt_BR")
        outputFormatter.dateFormat = "dd/MM/yyyy"
        return outputFormatter.string(from: date)
    }
}

struct DetailedExpense: Decodable, Identifiable, Hashable {
    var id: String { "\(expenseName)-\(date)-\(value)" }
    let expenseName: String
    let value: Double
    let date: String
    let category: String?

    enum CodingKeys: String, CodingKey {
        case expenseName
        case value
        case amount
        case date
        case category
    }

    init(expenseName: String, value: Double, date: String, category: String?) {
        self.expenseName = expenseName
        self.value = value
        self.date = date
        self.category = category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.expenseName = try container.decode(String.self, forKey: .expenseName)
        self.value = try container.decodeFlexibleDouble(primary: .value, fallback: .amount)
        self.date = Self.displayDate(from: try container.decode(String.self, forKey: .date))
        self.category = try container.decodeIfPresent(String.self, forKey: .category)
    }
    
    var formattedDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "pt_BR") // Assuming Brazilian Portuguese format
        return formatter.date(from: date) ?? Date()
    }

    private static func displayDate(from rawValue: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.locale = Locale(identifier: "pt_BR")
        inputFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = inputFormatter.date(from: rawValue) else { return rawValue }

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "pt_BR")
        outputFormatter.dateFormat = "dd/MM/yyyy"
        return outputFormatter.string(from: date)
    }

     static let mock = DetailedExpense(
              expenseName: "PIX ENVIADO Luciano Fabricio Rezende",
              value: 1503.54,
              date: "10/09/2025",
              category: "Outros / Transferências"
          )
}

private extension KeyedDecodingContainer {
    func decodeFlexibleDouble(primary: Key, fallback: Key) throws -> Double {
        if let value = try decodeIfPresent(Double.self, forKey: primary) {
            return value
        }
        if let value = try decodeIfPresent(Double.self, forKey: fallback) {
            return value
        }
        if let value = try decodeIfPresent(String.self, forKey: primary), let double = Double(value) {
            return double
        }
        if let value = try decodeIfPresent(String.self, forKey: fallback), let double = Double(value) {
            return double
        }
        return try decode(Double.self, forKey: primary)
    }

    func decodeFlexibleInt(primary: Key, fallback: Key) throws -> Int {
        if let value = try decodeIfPresent(Int.self, forKey: primary) {
            return value
        }
        if let value = try decodeIfPresent(Int.self, forKey: fallback) {
            return value
        }
        if let value = try decodeIfPresent(Int64.self, forKey: primary) {
            return Int(value)
        }
        if let value = try decodeIfPresent(Int64.self, forKey: fallback) {
            return Int(value)
        }
        if let value = try decodeIfPresent(String.self, forKey: primary), let int = Int(value) {
            return int
        }
        if let value = try decodeIfPresent(String.self, forKey: fallback), let int = Int(value) {
            return int
        }
        return try decode(Int.self, forKey: primary)
    }
}
