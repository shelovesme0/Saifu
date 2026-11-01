import Foundation

/// Категорії витрат. Загальні, без прив'язки до країни.
enum ExpenseCategory: CaseIterable {
    case food, groceries, smallShop, transport, household, leisure, untracked

    // switch по enum: назва українською
    var title: String {
        switch self {
        case .food: return "Їжа"
        case .groceries: return "Продукти"
        case .smallShop: return "Магазин біля дому"
        case .transport: return "Транспорт"
        case .household: return "Побут"
        case .leisure: return "Дозвілля"
        case .untracked: return "Невідстежене"
        }
    }

    var emoji: String {
        switch self {
        case .food: return "🍜"
        case .groceries: return "🛒"
        case .smallShop: return "🏪"
        case .transport: return "🚆"
        case .household: return "🧴"
        case .leisure: return "🎮"
        case .untracked: return "❓"
        }
    }
}
