//
//  SaifuApp.swift
//  Saifu
//
//  Created by Vitalii Lazariev on 01.11.2026.
//

import SwiftUI

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
        router: AppRouter()
    )

    var body: some Scene {
        WindowGroup {
            RootView(factory: factory)
        }
    }
}
