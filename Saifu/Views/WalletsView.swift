import SwiftUI

/// Список гаманців: тап — редагування, свайп — видалення з підтвердженням, перетягування — порядок.
struct WalletsView: View {
    @State private var viewModel: WalletsViewModel
    /// Гаманець, який чекає підтвердження видалення.
    @State private var walletPendingDelete: WalletSummary?
    /// Режим перетягування; власна кнопка замість EditButton, бо та показує системний текст англійською.
    @State private var editMode: EditMode = .inactive

    init(viewModel: WalletsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                ForEach(viewModel.wallets) { wallet in
                    Button { viewModel.walletTapped(wallet) } label: {
                        WalletRow(wallet: wallet)
                    }
                    .listRowBackground(Theme.card)
                    // Останній гаманець видалити не можна
                    .deleteDisabled(!viewModel.canDelete)
                }
                .onDelete { offsets in
                    walletPendingDelete = offsets.first.map { viewModel.wallets[$0] }
                }
                .onMove { source, destination in
                    viewModel.move(fromOffsets: source, toOffset: destination)
                }
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    if let message = viewModel.errorMessage {
                        Label(message, systemImage: "exclamationmark.circle")
                            .foregroundStyle(Theme.negative)
                    }
                    Text(viewModel.canDelete
                         ? "Свайп ліворуч — видалити. «Змінити» — перетягнути, щоб змінити порядок карток."
                         : "Останній гаманець видалити не можна.")
                        .foregroundStyle(Theme.secondaryText)
                }
                .font(Theme.captionFont)
            }

            Section {
                Button { viewModel.addTapped() } label: {
                    Label("Додати гаманець", systemImage: "plus.circle.fill")
                        .font(Theme.font(.body, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .listRowBackground(Theme.card)
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, $editMode)
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .font(Theme.bodyFont)
        .animation(.snappy, value: viewModel.wallets)
        .navigationTitle("Гаманці")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbar {
            // «Закрити» ліворуч, як у системних sheet
            ToolbarItem(placement: .cancellationAction) {
                Button("Закрити") { viewModel.doneTapped() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(editMode.isEditing ? "Готово" : "Змінити") {
                    withAnimation(.snappy) {
                        editMode = editMode.isEditing ? .inactive : .active
                    }
                }
                .fontWeight(editMode.isEditing ? .semibold : .regular)
            }
        }
        .confirmationDialog(
            "Видалити гаманець «\(walletPendingDelete?.title ?? "")»?",
            isPresented: Binding(get: { walletPendingDelete != nil },
                                 set: { if !$0 { walletPendingDelete = nil } }),
            titleVisibility: .visible,
            presenting: walletPendingDelete
        ) { wallet in
            Button("Видалити", role: .destructive) {
                withAnimation(.snappy) { viewModel.delete(id: wallet.id) }
            }
        } message: { _ in
            Text("Усі витрати й поповнення цього гаманця буде втрачено.")
        }
    }
}

/// Рядок гаманця: іконка, назва, валюта, баланс.
private struct WalletRow: View {
    let wallet: WalletSummary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wallet.bifold")
                .foregroundStyle(Theme.accent)
                .frame(width: 36, height: 36)
                .background(Theme.accent.opacity(0.16), in: Circle())
            VStack(alignment: .leading, spacing: 0) {
                Text(wallet.title)
                    .foregroundStyle(Theme.text)
                Text(wallet.currencyCode)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Text(wallet.balanceText)
                .font(Theme.font(.body, weight: .semibold))
                .foregroundStyle(wallet.isNegative ? Theme.negative : Theme.text)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    ScreenFactory.preview().view(for: .wallets)
}
