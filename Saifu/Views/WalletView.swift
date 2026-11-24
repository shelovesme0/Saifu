import SwiftUI

/// Головний екран: картки гаманців зі свайпом, швидке додавання, останні витрати.
struct WalletView: View {
    @Bindable var viewModel: WalletViewModel
    /// Фокус форми швидкого додавання: тут, щоб тап по порожньому місцю екрана закривав клавіатуру.
    @FocusState private var focus: QuickAddField?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if viewModel.hasWallets {
                    cards
                    if let addViewModel = viewModel.addExpenseViewModel {
                        QuickAddExpenseView(viewModel: addViewModel, focus: $focus)
                            .padding(.horizontal, Theme.gutter)
                    }
                    recent
                } else {
                    emptyState
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
            .dismissKeyboardOnBackgroundTap { focus = nil }
        }
        .scrollDismissesKeyboard(.interactively)
        // Гаманець додали чи видалили в налаштуваннях — картки оновлюються, вибір виправляється
        .onChange(of: viewModel.cards.map(\.id)) {
            viewModel.walletsChanged()
        }
        .themedScreen()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(viewModel.greeting)
                .font(Theme.font(.subheadline))
                .foregroundStyle(Theme.secondaryText)
            HStack {
                Text("Saifu")
                    .font(Theme.font(size: 34, weight: .bold))
                    .foregroundStyle(Theme.text)
                Spacer()
                Button { viewModel.manageWalletsTapped() } label: {
                    Image(systemName: "wallet.pass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .frame(width: 44, height: 44)
                        .background(Theme.card, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Керувати гаманцями")
            }
        }
        .padding(.horizontal, Theme.gutter)
    }

    private var cards: some View {
        VStack(spacing: 12) {
            TabView(selection: $viewModel.selectedWalletID) {
                ForEach(viewModel.cards) { card in
                    WalletCardView(card: card) {
                        viewModel.reconcileTapped(walletID: card.id)
                    }
                    .padding(.horizontal, Theme.gutter)
                    .tag(UUID?.some(card.id))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 210)

            PageDots(count: viewModel.cards.count, index: viewModel.selectedIndex)
        }
    }

    /// Перший запуск: гаманців ще немає.
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "wallet.bifold")
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent)
            Text("Гаманців ще немає")
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.text)
            Text("Створіть гаманець у валюті, якою розраховуєтеся готівкою, і вкажіть, скільки в ньому зараз.")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Створити перший гаманець") {
                viewModel.createFirstWalletTapped()
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .themedCard()
        .padding(.horizontal, Theme.gutter)
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Останні витрати")
                    .font(Theme.headlineFont)
                    .foregroundStyle(Theme.text)
                Spacer()
                Button("Усі") { viewModel.allExpensesTapped() }
                    .font(Theme.font(.subheadline, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }

            VStack(spacing: 0) {
                if viewModel.recentRows.isEmpty {
                    Text("Витрат ще немає")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
                ForEach(viewModel.recentRows) { row in
                    Button { viewModel.rowTapped(row) } label: {
                        ExpenseRowView(row: row)
                    }
                    .buttonStyle(.plain)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .themedCard(padding: 12)
        }
        .padding(.horizontal, Theme.gutter)
        .animation(.snappy, value: viewModel.recentRows)
    }
}

/// Картка гаманця з м'яким градієнтом.
private struct WalletCardView: View {
    let card: WalletCard
    let onReconcile: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Угорі: підпис ліворуч, чип гаманця праворуч
            HStack(alignment: .center) {
                Text("Готівка")
                    .font(Theme.font(.subheadline, weight: .medium))
                    .foregroundStyle(Theme.text.opacity(0.8))
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 1)
                Spacer()
                Text(card.title)
                    .font(Theme.font(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.background)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(Color.white, in: Capsule())
            }

            Spacer(minLength: 12)

            // Унизу: баланс ліворуч, «Звірити» праворуч
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.balanceText)
                        .font(Theme.balanceFont)
                        .foregroundStyle(card.isNegative ? Theme.negative : Theme.text)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    if let converted = card.convertedText {
                        Text(converted)
                            .font(Theme.font(.subheadline, weight: .semibold))
                            .foregroundStyle(Theme.text.opacity(0.9))
                            .contentTransition(.numericText())
                    }
                }
                // Легка тінь тримає білий текст читабельним на світлих плямах
                .shadow(color: .black.opacity(0.3), radius: 6, y: 1)

                Spacer(minLength: 0)

                Button(action: onReconcile) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                        Text("Звірити")
                            .font(Theme.font(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(Color.black.opacity(0.35), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 2)
            }
        }
        .padding(Theme.cardPadding + 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background {
            gradient.clipShape(RoundedRectangle(cornerRadius: Theme.bigCardRadius, style: .continuous))
        }
        .animation(.snappy, value: card)
    }

    /// Радіальні плями на темно-фіолетовій основі.
    private var gradient: some View {
        ZStack {
            Theme.cardBase
            RadialGradient(colors: [Theme.cardViolet, Theme.cardViolet.opacity(0)],
                           center: UnitPoint(x: 0.05, y: 1.0), startRadius: 0, endRadius: 280)
            RadialGradient(colors: [Theme.cardPeach.opacity(0.95), Theme.cardPeach.opacity(0)],
                           center: UnitPoint(x: 0.78, y: 0.6), startRadius: 0, endRadius: 190)
            RadialGradient(colors: [Theme.cardPink, Theme.cardPink.opacity(0)],
                           center: UnitPoint(x: 1.0, y: 0.0), startRadius: 0, endRadius: 250)
        }
    }
}

/// Поля форми швидкого додавання.
private enum QuickAddField { case amount, note }

/// Вбудована форма швидкого додавання: сума, «+», нотатка, категорія.
private struct QuickAddExpenseView: View {
    @Bindable var viewModel: AddExpenseViewModel
    var focus: FocusState<QuickAddField?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                AmountField(placeholder: "Сума", text: $viewModel.amountText, currency: viewModel.currency)
                    .focused(focus, equals: .amount)

                Button(action: add) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.background)
                        .frame(width: Theme.fieldHeight, height: Theme.fieldHeight)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .opacity(viewModel.canSave ? 1 : 0.4)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canSave)
                .accessibilityLabel("Додати витрату")
            }

            HStack(spacing: 10) {
                TextField("", text: $viewModel.note, prompt: Text("Нотатка").foregroundStyle(Theme.secondaryText))
                    .focused(focus, equals: .note)
                    .submitLabel(.done)
                    .onSubmit(add)
                    .themedField(height: Theme.compactFieldHeight)

                CategoryMenu(selection: $viewModel.category, compact: true)
            }

            if let suggested = viewModel.suggestedCategory, suggested == viewModel.category {
                Label("Категорію підказано за нотаткою", systemImage: "sparkles")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }

            if let message = viewModel.errorMessage {
                Label(message, systemImage: "exclamationmark.circle")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.negative)
            }
        }
        .themedCard(padding: 14)
        .animation(.snappy, value: viewModel.errorMessage)
    }

    /// «+» або «Готово» в полі нотатки: додає витрату й закриває клавіатуру.
    private func add() {
        focus.wrappedValue = nil
        guard viewModel.canSave else { return }
        withAnimation(.snappy) {
            _ = viewModel.save()
        }
    }
}

#Preview {
    // Через RootView, щоб у превʼю була й панель вкладок
    RootView(factory: .preview())
}
