import Foundation

/// Очищає введення суми: лише цифри та одна кома, не більше `minorUnits` знаків після неї.
enum AmountInputFilter {
    /// Ціла частина обмежена, щоб сума в найменших одиницях не переповнила Int.
    static let maxWholeDigits = 9

    /// "12a.3,45" → "123,45" для UAH і "12345" для JPY.
    static func sanitize(_ text: String, currency: Currency) -> String {
        var whole = ""
        var fraction = ""
        var hasSeparator = false

        for character in text {
            if character.isASCII, character.isNumber {
                if hasSeparator {
                    if fraction.count < currency.minorUnits { fraction.append(character) }
                } else if whole.count < maxWholeDigits {
                    whole.append(character)
                }
            } else if (character == "," || character == ".") && !hasSeparator && currency.minorUnits > 0 {
                hasSeparator = true
            }
            // Будь-які інші символи (літери, пробіли, друга кома) відкидаються
        }

        guard hasSeparator else { return whole }
        // ",5" → "0,5", щоб поле не починалося з коми
        return (whole.isEmpty ? "0" : whole) + "," + fraction
    }
}
