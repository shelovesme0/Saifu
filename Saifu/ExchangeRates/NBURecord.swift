import Foundation

/// Запис курсу у форматі НБУ. З JSON його отримує `NBURateDTO`.
struct NBURecord {
    let r030: Int
    let txt: String
    let rate: Decimal
    let cc: String
    /// Формат "dd.MM.yyyy".
    let exchangedate: String
}

/// Звідки беруться записи НБУ: мережа (`NBURemoteRecordSource`), демо-дані для превʼю, mock у Debug.
protocol NBURecordSource {
    func records() async throws -> [NBURecord]
}
