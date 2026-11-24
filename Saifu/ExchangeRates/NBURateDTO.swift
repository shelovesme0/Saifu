import Foundation

/// Елемент відповіді API НБУ, поля як у JSON:
/// `{"r030":392,"txt":"Єна","rate":0.28336,"cc":"JPY","exchangedate":"24.11.2026","special":null}`.
/// Зайві поля (`special`: null або "N") ігноруються.
struct NBURateDTO: Decodable {
    let r030: Int
    let txt: String
    let rate: Decimal
    let cc: String
    let exchangedate: String

    /// Перетворення у формат, з яким працює `NBURateAdapter`.
    var record: NBURecord {
        NBURecord(r030: r030, txt: txt, rate: rate, cc: cc, exchangedate: exchangedate)
    }
}
