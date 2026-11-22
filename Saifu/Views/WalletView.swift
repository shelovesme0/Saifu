import SwiftUI

/// Головний екран: перемикач гаманців, баланс, останні операції, дії.
struct WalletView: View {
    @Bindable var viewModel: WalletViewModel

    var body: some View {
        List {
            Section {
                Picker("Гаманець", selection: $viewModel.selectedWalletID) {
                    ForEach(viewModel.walletTabs) { tab in
                        Text(tab.title).tag(UUID?.some(tab.id))
                    }
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden)

                VStack(spacing: 4) {
                    Text(viewModel.walletName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(viewModel.balanceText)
                        .font(.largeTitle.bold())
                        .contentTransition(.numericText())
                    if let converted = viewModel.convertedBalanceText {
                        Text(converted)
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .animation(.default, value: viewModel.balanceText)
                .animation(.default, value: viewModel.convertedBalanceText)
            }

            Section {
                Button("+ Витрата", systemImage: "plus.circle.fill") { viewModel.addExpenseTapped() }
            }

            Section("Останні операції") {
                if viewModel.recentRows.isEmpty {
                    Text("Операцій ще немає")
                        .foregroundStyle(.secondary)
                }
                ForEach(viewModel.recentRows) { row in
                    EntryRowView(row: row)
                }
            }
        }
        .animation(.default, value: viewModel.recentRows)
        .navigationTitle("Saifu")
    }
}

#Preview {
    RootView(factory: .preview())
}
