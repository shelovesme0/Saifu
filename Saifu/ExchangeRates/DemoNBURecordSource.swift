import Foundation

/// Демо-записи у форматі НБУ. Значення курсів ілюстративні, не реальні.
struct DemoNBURecordSource: NBURecordSource {
    func records() async throws -> [NBURecord] {
        [
            NBURecord(r030: 392, txt: "Єна", rate: Decimal(string: "0.27")!, cc: "JPY", exchangedate: "02.11.2026"),
            NBURecord(r030: 840, txt: "Долар США", rate: Decimal(string: "41.50")!, cc: "USD", exchangedate: "02.11.2026"),
            NBURecord(r030: 978, txt: "Євро", rate: Decimal(string: "48.20")!, cc: "EUR", exchangedate: "02.11.2026")
        ]
    }
}
