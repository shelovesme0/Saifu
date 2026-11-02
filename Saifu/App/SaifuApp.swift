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
    @State private var viewModel = WalletViewModel(repository: DemoWalletRepository())

    var body: some Scene {
        WindowGroup {
            WalletView(viewModel: viewModel)
        }
    }
}
