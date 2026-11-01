import Foundation

/// Результат звірки гаманця з реальною готівкою.
struct Reconciliation {
    /// Очікуваний баланс за записами.
    let expected: Int
    /// Фактична сума готівки.
    let actual: Int
    let date: Date

    /// Різниця: додатна — недостача, від'ємна — надлишок.
    var difference: Int { expected - actual }

    init(expected: Int, actual: Int, date: Date = Date()) {
        self.expected = expected
        self.actual = actual
        self.date = date
    }
}
