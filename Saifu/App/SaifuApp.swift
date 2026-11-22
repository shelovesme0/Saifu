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
    // Композиційний корінь: тут обирається репозиторій (InMemoryWalletRepository() — порожній старт)
    @State private var factory = ScreenFactory(
        repository: DemoWalletRepository(),
        categoryStrategy: ChainedCategoryStrategy([
            LastUsedCategoryStrategy(),
            KeywordCategoryStrategy(dictionary: CategoryDictionaries.all)
        ]),
        rateProvider: NBURateAdapter(source: DemoNBURecordSource()),
        reminderScheduler: LocalReminderScheduler(center: .current()),
        defaults: .standard,
        appVersion: SaifuApp.appVersion,
        router: AppRouter()
    )

    var body: some Scene {
        WindowGroup {
            RootView(factory: factory)
        }
    }

    /// "1.0 (1)" з Info.plist.
    private static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
