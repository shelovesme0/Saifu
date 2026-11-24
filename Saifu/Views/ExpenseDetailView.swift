import SwiftUI

/// Деталі витрати: редагування та видалення з підтвердженням.
struct ExpenseDetailView: View {
    private enum Field { case amount, note }

    @State private var viewModel: ExpenseDetailViewModel
    @State private var isConfirmingDelete = false
    @FocusState private var focus: Field?

    init(viewModel: ExpenseDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(title: "Витрата", subtitle: viewModel.walletTitle) {
                    viewModel.backTapped()
                }

                if viewModel.isMissing {
                    VStack(spacing: 10) {
                        Image(systemName: "questionmark.folder")
                            .font(.system(size: 40))
                        Text("Витрату не знайдено")
                            .font(Theme.headlineFont)
                    }
                    .foregroundStyle(Theme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    form
                }
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 32)
            .dismissKeyboardOnBackgroundTap { focus = nil }
        }
        .scrollDismissesKeyboard(.interactively)
        .themedScreen()
        .toolbar(.hidden, for: .navigationBar)
        // Вкладений екран: панель вкладок ховаємо
        .toolbar(.hidden, for: .tabBar)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                fieldLabel("Сума")
                AmountField(placeholder: "Сума", text: $viewModel.amountText, currency: viewModel.currency)
                    .focused($focus, equals: .amount)

                fieldLabel("Категорія")
                CategoryMenu(selection: $viewModel.category)

                fieldLabel("Нотатка")
                TextField("", text: $viewModel.note, prompt: Text("Без нотатки").foregroundStyle(Theme.secondaryText))
                    .focused($focus, equals: .note)
                    .submitLabel(.done)
                    .onSubmit { focus = nil }
                    .themedField()

                Label(viewModel.dateText, systemImage: "calendar")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.top, 4)
            }
            .themedCard()

            if let message = viewModel.errorMessage {
                Label(message, systemImage: "exclamationmark.circle")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.negative)
            }

            Button {
                focus = nil
                withAnimation(.snappy) { viewModel.save() }
            } label: {
                Text("Зберегти")
                    .font(Theme.headlineFont)
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.fieldRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                isConfirmingDelete = true
            } label: {
                Label("Видалити витрату", systemImage: "trash")
                    .font(Theme.headlineFont)
                    .foregroundStyle(Theme.negative)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.fieldRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            // Діалог прив'язаний до кнопки, щоб на iOS 26 він з'являвся біля неї, а не внизу екрана
            .confirmationDialog("Видалити цю витрату?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Видалити", role: .destructive) {
                    withAnimation(.snappy) { viewModel.delete() }
                }
                Button("Скасувати", role: .cancel) {}
            } message: {
                Text("Баланс гаманця зміниться")
            }
        }
        .animation(.snappy, value: viewModel.errorMessage)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.captionFont)
            .foregroundStyle(Theme.secondaryText)
    }
}

#Preview {
    let factory = ScreenFactory.preview()
    return NavigationStack {
        factory.view(for: .expenseDetail(walletID: factory.previewWalletID, expenseID: factory.previewExpenseID))
    }
    .preferredColorScheme(.dark)
}
