import Foundation

/// Запис курсу у форматі НБУ (поля як у JSON API).
struct NBURecord: Decodable {
    let r030: Int
    let txt: String
    let rate: Decimal
    let cc: String
    /// Формат "dd.MM.yyyy".
    let exchangedate: String
}

/// Звідки беруться записи НБУ: демо-дані зараз, мережа в лабі 4.
protocol NBURecordSource {
    func records() async throws -> [NBURecord]
}
