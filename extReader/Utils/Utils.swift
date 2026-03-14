//
//  Utils.swift
//  extReader
//
//  Created by Renato Dias on 27/10/25.
//

import SwiftUI
import UIKit

extension String {
    static func errorDescription(_ code: String) -> String {
        switch code {
        case "404": return "Não Encontrado."
        default: return "Erro comunicando com o servidor."
        }
    }
}

// MARK: - Color for categories
extension Color {
    static func forCategory(_ category: String) -> Color {
        switch category {
        case "Roupas / Acessórios": return .purple
        case "E-commerce / Compras online": return .indigo
        case "Restaurante / Lanches": return .orange
        case "Investimentos / Assinaturas profissionais": return .blue
        case "Saúde / Farmácia / Bem-estar": return .red
        case "Transporte / Auto": return .gray
        case "Lazer / Entretenimento / Pets": return .yellow
        case "Supermercado": return .green
        case "Outros / Transferências": return .brown
        case "Moradia / Contas": return .mint
        default: return .secondary
        }
    }
}

// MARK: - Icon for categories
extension String {
    static func iconName(forCategory category: String) -> String {
        switch category {
        case "Roupas / Acessórios": return "tshirt.fill"
        case "E-commerce / Compras online": return "bag.fill"
        case "Restaurante / Lanches": return "fork.knife"
        case "Investimentos / Assinaturas profissionais": return "briefcase.fill"
        case "Saúde / Farmácia / Bem-estar": return "cross.fill"
        case "Transporte / Auto": return "car.fill"
        case "Lazer / Entretenimento / Pets": return "gamecontroller.fill"
        case "Supermercado": return "cart.fill"
        case "Outros / Transferências": return "arrow.right.arrow.left"
        case "Moradia / Contas": return "house.fill"
        default: return "questionmark"
        }
    }
}

extension UIColor {
    static func forCategory(_ category: String) -> UIColor {
        switch category {
        case "Roupas / Acessórios": return .purple
        case "E-commerce / Compras online": return .systemIndigo
        case "Restaurante / Lanches": return .systemOrange
        case "Investimentos / Assinaturas profissionais": return .systemBlue
        case "Saúde / Farmácia / Bem-estar": return .systemRed
        case "Transporte / Auto": return .systemGray
        case "Lazer / Entretenimento / Pets": return .systemYellow
        case "Supermercado": return .systemGreen
        case "Outros / Transferências": return .brown
        case "Moradia / Contas": return .systemMint
        default: return .secondaryLabel
        }
    }
}

extension Bundle {
    func decode<T: Decodable>(_ type: T.Type, from file: String) -> T {
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("❌ Failed to find \(file) in bundle.")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("❌ Failed to load \(file) from bundle.")
        }

        let decoder = JSONDecoder()
        return try! decoder.decode(T.self, from: data)
    }
}
