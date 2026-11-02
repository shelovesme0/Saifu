import SwiftUI

struct WalletView: View {
    @Bindable var viewModel: WalletViewModel
    @State private var amountText = ""
    @State private var category: ExpenseCategory = .food

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
            }

            Section("Нова витрата") {
                TextField("Сума", text: $amountText)
                    .keyboardType(.decimalPad)
                Picker("Категорія", selection: $category) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Text("\(category.emoji) \(category.title)").tag(category)
                    }
                }
                if let message = viewModel.errorMessage {
                    Text(message)
                        .foregroundStyle(.red)
                }
                Button("Додати") {
                    if viewModel.addExpense(amountText: amountText, category: category) {
                        amountText = ""
                    }
                }
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
    }
}

#Preview {
    WalletView(viewModel: WalletViewModel(repository: DemoWalletRepository()))
}
