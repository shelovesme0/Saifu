import Foundation

/// Валюта гаманця. Щоб додати нову, досить додати кейс і рядок у `symbol` та `minorUnits`.
enum Currency: String, CaseIterable {
    case jpy, uah, eur, usd

    /// Код валюти, наприклад "JPY".
    var code: String { rawValue.uppercased() }

    // switch по enum: компілятор вимагає покрити всі кейси
    var symbol: String {
        switch self {
        case .jpy: return "¥"
        case .uah: return "₴"
        case .eur: return "€"
        case .usd: return "$"
        }
    }

    /// Кількість знаків після коми (єни — 0, решта — 2).
    var minorUnits: Int {
        switch self {
        case .jpy: return 0
        case .uah, .eur, .usd: return 2
        }
    }

    /// Форматує суму в найменших одиницях: 4550 UAH -> "45,50 ₴", 20000 JPY -> "20 000 ¥".
    func format(_ minor: Int) -> String {
        // Розділяємо цілу й дробову частини без Double
        var divisor = 1
        for _ in 0..<minorUnits { divisor *= 10 } // for-in
        let absolute = abs(minor)
        let major = absolute / divisor
        let fraction = absolute % divisor

        var result = (minor < 0 ? "-" : "") + groupThousands(major)
        if minorUnits > 0 {
            let digits = String(fraction)
            // Доповнюємо дробову частину нулями зліва: 5 -> "05"
            let padding = String(repeating: "0", count: minorUnits - digits.count)
            result += "," + padding + digits
        }
        return "\(result) \(symbol)"
    }

    /// Ставить пробіл між тисячами: 1000000 -> "1 000 000".
    private func groupThousands(_ value: Int) -> String {
        let digits = Array(String(value))
        var result = ""
        for (index, digit) in digits.enumerated() { // for-in з enumerated
            // Пробіл перед цифрою, після якої лишається кратна 3 кількість цифр
            if index > 0 && (digits.count - index) % 3 == 0 {
                result += " "
            }
            result.append(digit)
        }
        return result
    }
}
