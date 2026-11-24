import Foundation

/// Декоратор репозиторію: після кожної успішної зміни (збереження гаманця, видалення, порядок, імпорт)
/// викликає `onChange`. Усі зміни даних проходять через репозиторій, тож автокопія дізнається про кожну,
/// а ViewModel екранів про неї нічого не знають.
final class ChangeNotifyingWalletRepository: WalletRepository {
    private let inner: WalletRepository
    /// Задається після створення підписника (BackupViewModel створюється пізніше за репозиторій).
    var onChange: () -> Void = {}

    init(inner: WalletRepository) {
        self.inner = inner
    }

    func wallets() -> [CashWallet] {
        inner.wallets()
    }

    func save(_ wallet: CashWallet) throws {
        try inner.save(wallet)
        onChange()
    }

    func remove(id: CashWallet.ID) throws {
        try inner.remove(id: id)
        onChange()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) throws {
        try inner.move(fromOffsets: source, toOffset: destination)
        onChange()
    }

    func replaceAll(with wallets: [CashWallet]) throws {
        try inner.replaceAll(with: wallets)
        onChange()
    }
}
