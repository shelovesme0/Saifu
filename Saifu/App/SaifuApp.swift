//
//  SaifuApp.swift
//  Saifu
//
//  Created by Vitalii Lazariev on 01.11.2026.
//

import SwiftUI
import UserNotifications

@main
struct SaifuApp: App {
    // Композиційний корінь: тут обирається репозиторій (makeRepository) і решта залежностей
    @State private var factory: ScreenFactory = {
        let storage = SaifuApp.makeRepository()
        let rateCache = SaifuApp.makeRateSource()
        return ScreenFactory(
            repository: storage.repository,
            categoryStrategy: ChainedCategoryStrategy([
                LastUsedCategoryStrategy(),
                KeywordCategoryStrategy(dictionary: CategoryDictionaries.all)
            ]),
            rateProvider: NBURateAdapter(source: rateCache),
            rateCache: rateCache,
            reminderScheduler: LocalReminderScheduler(center: .current()),
            defaults: .standard,
            appVersion: SaifuApp.appVersion,
            router: AppRouter(),
            startupWarning: storage.warning
        )
    }()

    var body: some Scene {
        WindowGroup {
            RootView(factory: factory)
        }
    }

    /// Звичайний запуск (Debug і Release) — гаманці на диску через SwiftData.
    /// Лише Debug з `-uiScreen` — демо-дані в пам'яті, щоб скриншоти не залежали від збереженого.
    /// Якщо сховище не відкрилося, застосунок працює з порожнім сховищем у пам'яті й попереджає про це.
    private static func makeRepository() -> (repository: WalletRepository, warning: String?) {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiScreen") {
            return (DemoWalletRepository(), nil)
        }
        #endif
        do {
            let container = try SaifuMigrationPlan.makeContainer(inMemory: false)
            return (SwiftDataWalletRepository(container: container), nil)
        } catch {
            let warning = "Не вдалося відкрити збережені дані. Зміни в цьому сеансі не збережуться."
            if let container = try? SaifuMigrationPlan.makeContainer(inMemory: true) {
                return (SwiftDataWalletRepository(container: container), warning)
            }
            return (InMemoryWalletRepository(), warning)
        }
    }

    /// Курси НБУ з мережі з кешем на день.
    private static func makeRateSource() -> CachedRecordSource {
        CachedRecordSource(source: NBURemoteRecordSource(client: URLSessionHTTPClient()))
    }

    /// "1.0 (1)" з Info.plist.
    private static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
