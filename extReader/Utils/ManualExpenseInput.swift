import Foundation
import Combine

enum ExpenseCategories {
    static let all = [
        "Roupas / Acessórios", "E-commerce / Compras online", "Restaurante / Lanches",
        "Investimentos / Assinaturas profissionais", "Saúde / Farmácia / Bem-estar",
        "Transporte / Auto", "Lazer / Entretenimento / Pets", "Supermercado",
        "Outros / Transferências", "Moradia / Contas"
    ]
}

// Strict parsing avoids accepting a partial number or silently changing an invalid amount.
enum ManualExpenseInput {
    static func amount(_ text: String) -> Decimal? {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^(?:[0-9]+|[0-9]{1,3}(?:\.[0-9]{3})+)(?:,[0-9]{1,2})?$"#
        guard text.range(of: pattern, options: .regularExpression) != nil,
              let value = Decimal(string: text.replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX")),
              !value.isNaN, value > 0 else { return nil }
        return value
    }

    static func date(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
