import SwiftUI

struct WalletView: View {
    @Bindable var viewModel: WalletViewModel

    var body: some View {
        List {
            Section {
                Picker("Гаманець", selection: $viewModel.selectedIndex) {
                    ForEach(viewModel.walletNames.indices, id: \.self) { index in
                        Text(viewModel.walletNames[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                Text(viewModel.balanceText)
                    .font(.largeTitle)
                if let converted = viewModel.convertedBalanceText {
                    Text(converted)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("+ Витрата") { viewModel.addExpenseTapped() }
            }

            Section("Операції") {
                ForEach(viewModel.rows) { row in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(row.title)
                            if let subtitle = row.subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(row.amountText)
                            .foregroundStyle(row.isNegative ? .red : .green)
                    }
                }
            }
        }
        .navigationTitle("Saifu")
    }
}

#Preview {
    RootView(factory: .preview())
}
