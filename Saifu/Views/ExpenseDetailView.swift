import SwiftUI

/// Деталі витрати: форма редагування та видалення з підтвердженням.
struct ExpenseDetailView: View {
    @State private var viewModel: ExpenseDetailViewModel
    @State private var isConfirmingDelete = false

    init(viewModel: ExpenseDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isMissing {
                ContentUnavailableView("Витрату не знайдено", systemImage: "questionmark.folder")
            } else {
                form
            }
        }
        .navigationTitle("Витрата")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var form: some View {
        Form {
            Section {
                LabeledContent("Сума, \(viewModel.currencySymbol)") {
                    TextField("Сума", text: $viewModel.amountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                CategoryPicker(selection: $viewModel.category)
                TextField("Нотатка", text: $viewModel.note)
            } footer: {
                Text(viewModel.dateText)
            }

            if let message = viewModel.errorMessage {
                Section {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button("Видалити витрату", role: .destructive) {
                    isConfirmingDelete = true
                }
            }
        }
        .animation(.default, value: viewModel.errorMessage)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Зберегти") { viewModel.save() }
            }
        }
        .confirmationDialog("Видалити цю витрату?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Видалити", role: .destructive) { viewModel.delete() }
        }
    }
}

#Preview {
    let factory = ScreenFactory.preview()
    return NavigationStack {
        factory.view(for: .expenseDetail(walletID: factory.previewWalletID, expenseID: factory.previewExpenseID))
    }
}
