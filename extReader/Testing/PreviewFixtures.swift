//
//  PreviewFixtures.swift
//  extReader
//

import Foundation

#if DEBUG
extension ExpenseResponse {
    static let preview = ExpenseResponse(
        SmartGroupExpenselist: [
            GroupedExpense(
                expenseName: "Mercado Central",
                total: 248.90,
                instances: 2,
                category: "Supermercado"
            ),
            GroupedExpense(
                expenseName: "Cafe Aurora",
                total: 68.40,
                instances: 2,
                category: "Restaurante / Lanches"
            ),
            GroupedExpense(
                expenseName: "Posto Avenida",
                total: 180.00,
                instances: 1,
                category: "Transporte / Auto"
            ),
            GroupedExpense(
                expenseName: "PIX Enviado",
                total: 120.00,
                instances: 1,
                category: ""
            )
        ],
        AllExpenses: [
            DetailedExpense(
                expenseName: "Mercado Central",
                value: 128.90,
                date: "03/08/2026",
                category: "Supermercado"
            ),
            DetailedExpense(
                expenseName: "Mercado Central",
                value: 120.00,
                date: "11/08/2026",
                category: "Supermercado"
            ),
            DetailedExpense(
                expenseName: "Cafe Aurora",
                value: 42.40,
                date: "04/08/2026",
                category: "Restaurante / Lanches"
            ),
            DetailedExpense(
                expenseName: "Cafe Aurora",
                value: 26.00,
                date: "12/08/2026",
                category: "Restaurante / Lanches"
            ),
            DetailedExpense(
                expenseName: "Posto Avenida",
                value: 180.00,
                date: "10/08/2026",
                category: "Transporte / Auto"
            ),
            DetailedExpense(
                expenseName: "PIX Enviado",
                value: 120.00,
                date: "12/08/2026",
                category: nil
            )
        ],
        sessionToken: "preview-report",
        BiggestSingularExpense: DetailedExpense(
            expenseName: "Posto Avenida",
            value: 180.00,
            date: "10/08/2026",
            category: "Transporte / Auto"
        ),
        NotableDays: [
            NotableDay(date: "12/08/2026", total: 146.00, transactions: 2),
            NotableDay(date: "03/08/2026", total: 128.90, transactions: 1)
        ],
        ExpensesByCategory: [
            TotalByCategory(category: "Supermercado", value: 248.90),
            TotalByCategory(category: "Transporte / Auto", value: 180.00),
            TotalByCategory(category: "Restaurante / Lanches", value: 68.40),
            TotalByCategory(category: "Outros / Transferências", value: 120.00)
        ]
    )
}
#endif
