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
        Color(uiColor: .forCategory(category))
    }
}

// MARK: - Icon for categories
extension String {
    static func iconName(forCategory category: String) -> String {
        if category == "Outras" || category.hasPrefix("Outras (") { return "ellipsis" }
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
        let light: UIColor
        let darkHex: UInt
        switch category {
        case "Roupas / Acessórios": (light, darkHex) = (.systemPurple, 0xBE9ADE)
        case "E-commerce / Compras online": (light, darkHex) = (.systemIndigo, 0x9B9FE4)
        case "Restaurante / Lanches": (light, darkHex) = (.systemOrange, 0xE6A06B)
        case "Investimentos / Assinaturas profissionais": (light, darkHex) = (.systemBlue, 0x80ADE0)
        case "Saúde / Farmácia / Bem-estar": (light, darkHex) = (.systemRed, 0xDF8790)
        case "Transporte / Auto": (light, darkHex) = (.systemGray, 0xA7AFBC)
        case "Lazer / Entretenimento / Pets": (light, darkHex) = (.systemYellow, 0xD9C477)
        case "Supermercado": (light, darkHex) = (UIColor(red: 0.43, green: 0.51, blue: 0.19, alpha: 1), 0xAFBF78)
        case "Outros / Transferências": (light, darkHex) = (.brown, 0xBEA18B)
        case "Moradia / Contas": (light, darkHex) = (.systemTeal, 0x73BCCB)
        default: (light, darkHex) = (.secondaryLabel, 0xA1A1A8)
        }
        return UIColor { traits in
            guard traits.userInterfaceStyle == .dark else { return light }
            return UIColor(red: CGFloat((darkHex >> 16) & 255) / 255,
                           green: CGFloat((darkHex >> 8) & 255) / 255,
                           blue: CGFloat(darkHex & 255) / 255, alpha: 1)
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
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("❌ Failed to decode \(file): \(error)")
        }
    }
}
