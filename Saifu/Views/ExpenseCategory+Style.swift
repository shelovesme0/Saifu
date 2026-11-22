import SwiftUI

/// Вигляд категорій в інтерфейсі: SF Symbol і колір. Модель про це не знає.
extension ExpenseCategory {
    var symbolName: String {
        switch self {
        case .food: return "fork.knife"
        case .groceries: return "cart"
        case .smallShop: return "storefront"
        case .transport: return "tram"
        case .household: return "house"
        case .leisure: return "gamecontroller"
        case .untracked: return "questionmark"
        }
    }

    var color: Color {
        switch self {
        case .food: return Color(hex: 0xFF9F7A)
        case .groceries: return Color(hex: 0x7ED9A0)
        case .smallShop: return Color(hex: 0xF2C6DE)
        case .transport: return Color(hex: 0x6FB7FF)
        case .household: return Color(hex: 0xFFD36E)
        case .leisure: return Color(hex: 0x8C7BFF)
        case .untracked: return Color(hex: 0x8E8E98)
        }
    }
}
