//
//  ExpensesView.swift
//  extReader
//
//  Created by Renato Dias on 28/10/25.
//

import SwiftUI

enum ExpenseSortOption: String, CaseIterable {
    case total = "Valor"
    case frequency = "Frequência"
    case name = "Nome"
    case category = "Categoria"
}

struct ExpensesView: View {
    let groupedList: [GroupedExpense]
    let allExpenses: [DetailedExpense]

    @State private var sortOption: ExpenseSortOption = .total
    @State private var sortAscending = false
    @State private var selectedCategory: String? = nil

    private var categories: [String] {
        Array(Set(groupedList.map(\.category))).sorted()
    }

    private var filteredAndSorted: [GroupedExpense] {
        var list = groupedList

        if let cat = selectedCategory {
            list = list.filter { $0.category == cat }
        }

        switch sortOption {
        case .total:
            list.sort { sortAscending ? $0.total < $1.total : $0.total > $1.total }
        case .frequency:
            list.sort { sortAscending ? $0.instances < $1.instances : $0.instances > $1.instances }
        case .name:
            list.sort { sortAscending ? $0.expenseName.localizedCompare($1.expenseName) == .orderedAscending : $0.expenseName.localizedCompare($1.expenseName) == .orderedDescending }
        case .category:
            list.sort {
                let cmp = $0.category.localizedCompare($1.category)
                if cmp == .orderedSame {
                    return $0.total > $1.total
                }
                return sortAscending ? cmp == .orderedAscending : cmp == .orderedDescending
            }
        }

        return list
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Todas Despesas")
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                        Text("\(groupedList.count) itens agrupados")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    // Sort direction toggle
                    Button {
                        withAnimation(.snappy(duration: 0.2)) {
                            sortAscending.toggle()
                        }
                    } label: {
                        Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color(.quaternarySystemFill))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 4)

                // Sort pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ExpenseSortOption.allCases, id: \.self) { option in
                            Button {
                                withAnimation(.snappy(duration: 0.2)) {
                                    if sortOption == option {
                                        sortAscending.toggle()
                                    } else {
                                        sortOption = option
                                        sortAscending = false
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(option.rawValue)
                                        .font(.subheadline.weight(sortOption == option ? .semibold : .regular))
                                    if sortOption == option {
                                        Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                                            .font(.caption2.weight(.bold))
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(sortOption == option ? Color.accentColor.opacity(0.15) : Color(.quaternarySystemFill))
                                )
                                .foregroundColor(sortOption == option ? .accentColor : .secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }

                // Category filter pills
                if categories.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // "All" pill
                            Button {
                                withAnimation(.snappy(duration: 0.2)) {
                                    selectedCategory = nil
                                }
                            } label: {
                                Text("Todas")
                                    .font(.caption.weight(selectedCategory == nil ? .semibold : .regular))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(selectedCategory == nil ? Color.accentColor.opacity(0.15) : Color(.quaternarySystemFill))
                                    )
                                    .foregroundColor(selectedCategory == nil ? .accentColor : .secondary)
                            }

                            ForEach(categories, id: \.self) { cat in
                                let catColor = Color.forCategory(cat)
                                Button {
                                    withAnimation(.snappy(duration: 0.2)) {
                                        selectedCategory = selectedCategory == cat ? nil : cat
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: String.iconName(forCategory: cat))
                                            .font(.caption2)
                                        Text(cat)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(selectedCategory == cat ? catColor.opacity(0.15) : Color(.quaternarySystemFill))
                                    )
                                    .foregroundColor(selectedCategory == cat ? catColor : .secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }

                // Expense list
                let sorted = filteredAndSorted
                if sorted.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text("Nenhuma despesa encontrada")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    VStack(spacing: 0) {
                        ForEach(sorted) { expense in
                            let expenses = allExpenses.filter { $0.expenseName == expense.expenseName }

                            NavigationLink {
                                if expense.instances == 1, let single = expenses.first {
                                    ExpenseDetailView(expense: single)
                                } else {
                                    CategoryListView(category: expense.expenseName, expenses: expenses, total: expense.total)
                                }
                            } label: {
                                GroupedExpenseListItemView(expense: expense)
                                    .padding()
                            }
                            .foregroundColor(.primary)
                        }
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.bottom)
                    }
                }
            }
            .padding(.top)
        }
        .padding(.horizontal, 8)
    }
}
