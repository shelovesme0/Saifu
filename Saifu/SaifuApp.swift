//
//  SaifuApp.swift
//  Saifu
//
//  Created by Vitalii Lazariev on 01.11.2026.
//

import SwiftUI

@main
struct SaifuApp: App {
    // Демо-сценарій виконується один раз при старті і друкує кроки в консоль
    @State private var wallets = DemoScenario.run()

    var body: some Scene {
        WindowGroup {
            ContentView(wallets: wallets)
        }
    }
}
