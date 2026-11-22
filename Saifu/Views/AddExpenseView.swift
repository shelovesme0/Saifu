import SwiftUI

/// Sheet «Нова витрата»: форма показує стан AddExpenseViewModel і викликає лише її.
struct AddExpenseView: View {
    @State private var viewModel: AddExpenseViewModel

    init(viewModel: AddExpenseViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Сума", text: $viewModel.amountText)
                        .keyboardType(.decimalPad)
                    TextField("Нотатка", text: $viewModel.note)
                    CategoryPicker(selection: $viewModel.category)
                } header: {
                    Text(viewModel.walletTitle)
                } footer: {
                    if let suggested = viewModel.suggestedCategory {
                        Text("Підказка: \(suggested.emoji) \(suggested.title)")
                    }
                }

                if let message = viewModel.errorMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(.red)
                    }
                }
            }
            .animation(.default, value: viewModel.errorMessage)
            .navigationTitle("Нова витрата")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { viewModel.cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Додати") { viewModel.save() }
                }
            }
        }
    }
}

#Preview {
    let factory = ScreenFactory.preview()
    return factory.view(for: .addExpense(walletID: factory.previewWalletID))
}
