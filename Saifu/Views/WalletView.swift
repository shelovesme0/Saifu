import SwiftUI

struct WalletView: View {
    @Bindable var viewModel: WalletViewModel
    @State private var amountText = ""
    @State private var category: ExpenseCategory?
    @State private var note = ""

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

            Section("Нова витрата") {
                TextField("Сума", text: $amountText)
                    .keyboardType(.decimalPad)
                TextField("Нотатка", text: $note)
                    .onChange(of: note) {
                        if let suggested = viewModel.suggestedCategory(for: note) {
                            category = suggested
                        }
                    }
                Picker("Категорія", selection: $category) {
                    Text("— оберіть —").tag(ExpenseCategory?.none)
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Text("\(category.emoji) \(category.title)").tag(ExpenseCategory?.some(category))
                    }
                }
                if let message = viewModel.errorMessage {
                    Text(message)
                        .foregroundStyle(.red)
                }
                Button("Додати") {
                    if viewModel.addExpense(amountText: amountText, category: category, note: note) {
                        amountText = ""
                        note = ""
                        category = nil
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
    WalletView(viewModel: WalletViewModel(
        repository: DemoWalletRepository(),
        categoryStrategy: ChainedCategoryStrategy([
            LastUsedCategoryStrategy(),
            KeywordCategoryStrategy(dictionary: CategoryDictionaries.all)
        ]),
        rateProvider: NBURateAdapter(source: DemoNBURecordSource())
    ))
}
