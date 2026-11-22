import SwiftUI

/// Форма гаманця: новий (назва, валюта, початкова сума) або редагування (назва; валюта — лише без записів).
struct WalletFormView: View {
    private enum Field { case name, amount }

    @State private var viewModel: WalletFormViewModel
    @FocusState private var focus: Field?

    init(viewModel: WalletFormViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    label("Назва")
                    TextField("", text: $viewModel.name,
                              prompt: Text("Напр. Долари").foregroundStyle(Theme.secondaryText))
                        .focused($focus, equals: .name)
                        .submitLabel(.done)
                        .onSubmit { focus = nil }
                        .themedField()

                    label("Валюта")
                    ChipPicker(options: Currency.allCases,
                               selection: $viewModel.currency,
                               title: { "\($0.code) \($0.symbol)" })
                        .disabled(!viewModel.canChangeCurrency)
                        .opacity(viewModel.canChangeCurrency ? 1 : 0.5)
                    if let hint = viewModel.currencyHint {
                        Text(hint)
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.secondaryText)
                    }

                    if viewModel.isNew {
                        label("Початкова сума (необов'язково)")
                        AmountField(placeholder: "0", text: $viewModel.initialAmountText, currency: viewModel.currency)
                            .focused($focus, equals: .amount)
                        Text("Буде записана як поповнення гаманця")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .themedCard()

                if let message = viewModel.errorMessage {
                    Label(message, systemImage: "exclamationmark.circle")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.negative)
                }

                PrimaryButton(title: viewModel.isNew ? "Створити" : "Зберегти", isEnabled: viewModel.canSave) {
                    focus = nil
                    withAnimation(.snappy) { viewModel.save() }
                }
            }
            .padding(Theme.gutter)
            .dismissKeyboardOnBackgroundTap { focus = nil }
            .animation(.snappy, value: viewModel.errorMessage)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .onAppear {
            if viewModel.isNew { focus = .name }
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(Theme.captionFont)
            .foregroundStyle(Theme.secondaryText)
    }
}

#Preview {
    NavigationStack {
        ScreenFactory.preview().view(for: .addWallet)
    }
    .preferredColorScheme(.dark)
}
