//
//  ContentView.swift
//  Saifu
//
//  Created by Vitalii Lazariev on 01.11.2026.
//

import SwiftUI

struct ContentView: View {
    let wallets: [CashWallet]

    var body: some View {
        List {
            ForEach(wallets, id: \.name) { wallet in
                Section {
                    ForEach(wallet.topUps) { topUp in
                        row(title: topUp.source == .atm ? "🏧 Поповнення" : "➕ Коригування",
                            subtitle: nil,
                            amount: topUp.signedAmount,
                            currency: wallet.currency)
                    }
                    ForEach(wallet.expenses) { expense in
                        row(title: "\(expense.category.emoji) \(expense.category.title)",
                            subtitle: expense.note,
                            amount: expense.signedAmount,
                            currency: wallet.currency)
                    }
                } header: {
                    Text("\(wallet.name) — \(wallet.formattedBalance)")
                        .font(.headline)
                }
            }
        }
    }

    private func row(title: String, subtitle: String?, amount: Int, currency: Currency) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(currency.format(amount))
                .foregroundStyle(amount < 0 ? .red : .green)
        }
    }
}

#Preview {
    ContentView(wallets: DemoScenario.run())
}
