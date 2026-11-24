import Foundation
import Observation
import SwiftData

/// Зберігає гаманці на диску через SwiftData.
/// При запуску один раз читає сховище й тримає гаманці в пам'яті як спільні екземпляри `CashWallet`;
/// кожна зміна одразу записується. ViewModel про SwiftData не знають — лише про `WalletRepository`.
@Observable
final class SwiftDataWalletRepository: WalletRepository {
    private var storage: [CashWallet] = []
    /// Контейнер тримаємо самі: контекст не утримує його, і без цього сховище закриється.
    @ObservationIgnored private let container: ModelContainer
    @ObservationIgnored private let context: ModelContext
    /// Сутності гаманців за id: читаються один раз при запуску, далі оновлюються разом зі `storage`.
    @ObservationIgnored private var entities: [CashWallet.ID: WalletEntity] = [:]

    init(container: ModelContainer) {
        self.container = container
        context = container.mainContext
        // Зберігаємо явно після кожної дії, щоб помилку можна було показати одразу
        context.autosaveEnabled = false
        let descriptor = FetchDescriptor<WalletEntity>(sortBy: [SortDescriptor(\.sortIndex)])
        for entity in (try? context.fetch(descriptor)) ?? [] {
            guard let wallet = entity.toDomain() else { continue }
            storage.append(wallet)
            entities[wallet.id] = entity
        }
    }

    func wallets() -> [CashWallet] {
        storage
    }

    func save(_ wallet: CashWallet) throws {
        if !storage.contains(where: { $0.id == wallet.id }) {
            storage.append(wallet)
        }
        let entity = entities[wallet.id] ?? insertEntity(for: wallet)
        // Синхронізуємо весь гаманець: якщо минуле збереження не вдалося, ці зміни теж запишуться
        entity.update(from: wallet)
        syncExpenses(of: entity, with: wallet.expenses)
        syncTopUps(of: entity, with: wallet.topUps)
        syncReconciliation(of: entity, with: wallet.lastReconciliation)
        try commit()
    }

    func remove(id: CashWallet.ID) throws {
        storage.removeAll { $0.id == id }
        guard let entity = entities.removeValue(forKey: id) else { return }
        // Витрати, поповнення і звірку видаляє каскадне правило
        context.delete(entity)
        try commit()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) throws {
        let moving = source.map { storage[$0] }
        // Індекс вставки зсувається на кількість елементів, що стояли перед ним
        let insertAt = destination - source.filter { $0 < destination }.count
        for index in source.sorted(by: >) {
            storage.remove(at: index)
        }
        storage.insert(contentsOf: moving, at: min(max(insertAt, 0), storage.count))

        for (index, wallet) in storage.enumerated() {
            entities[wallet.id]?.sortIndex = index
        }
        try commit()
    }

    func replaceAll(with wallets: [CashWallet]) throws {
        // Видаляємо всі сутності (а не лише відомі), щоб у сховищі не лишилося нічого зі старих даних
        let stored = (try? context.fetch(FetchDescriptor<WalletEntity>())) ?? []
        for entity in stored {
            context.delete(entity)
        }
        var newEntities: [CashWallet.ID: WalletEntity] = [:]
        for (index, wallet) in wallets.enumerated() {
            let entity = WalletEntity(id: wallet.id,
                                      name: wallet.name,
                                      currencyRaw: wallet.currency.rawValue,
                                      sortIndex: index)
            context.insert(entity)
            entity.expenses = wallet.expenses.map { ExpenseEntity($0) }
            entity.topUps = wallet.topUps.map { TopUpEntity($0) }
            entity.lastReconciliation = wallet.lastReconciliation.map { ReconciliationEntity($0) }
            newEntities[wallet.id] = entity
        }
        // Пам'ять оновлюємо лише після успішного запису: при помилці commit() відкотить контекст
        try commit()
        entities = newEntities
        storage = wallets
    }

    // MARK: - Сховище

    private func insertEntity(for wallet: CashWallet) -> WalletEntity {
        // Новий гаманець — у кінець списку
        let nextIndex = (entities.values.map(\.sortIndex).max() ?? -1) + 1
        let entity = WalletEntity(id: wallet.id,
                                  name: wallet.name,
                                  currencyRaw: wallet.currency.rawValue,
                                  sortIndex: nextIndex)
        context.insert(entity)
        entities[wallet.id] = entity
        return entity
    }

    /// Додає нові, оновлює змінені й видаляє зниклі витрати (за id).
    private func syncExpenses(of entity: WalletEntity, with expenses: [Expense]) {
        let ids = Set(expenses.map(\.id))
        for stored in entity.expenses where !ids.contains(stored.id) {
            context.delete(stored)
        }
        entity.expenses.removeAll { !ids.contains($0.id) }

        for expense in expenses {
            if let stored = entity.expenses.first(where: { $0.id == expense.id }) {
                stored.update(from: expense)
            } else {
                entity.expenses.append(ExpenseEntity(expense))
            }
        }
    }

    private func syncTopUps(of entity: WalletEntity, with topUps: [CashTopUp]) {
        let ids = Set(topUps.map(\.id))
        for stored in entity.topUps where !ids.contains(stored.id) {
            context.delete(stored)
        }
        entity.topUps.removeAll { !ids.contains($0.id) }

        for topUp in topUps {
            if let stored = entity.topUps.first(where: { $0.id == topUp.id }) {
                stored.update(from: topUp)
            } else {
                entity.topUps.append(TopUpEntity(topUp))
            }
        }
    }

    private func syncReconciliation(of entity: WalletEntity, with reconciliation: Reconciliation?) {
        let stored = entity.lastReconciliation
        // Та сама звірка — нічого не змінюємо
        if stored?.date == reconciliation?.date && stored?.expected == reconciliation?.expected {
            return
        }
        if let stored {
            context.delete(stored)
        }
        entity.lastReconciliation = reconciliation.map { ReconciliationEntity($0) }
    }

    /// Записує зміни на диск. При помилці скасовує незбережене, щоб не лишити сховище напівзміненим.
    private func commit() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw RepositoryError.saveFailed
        }
    }
}
