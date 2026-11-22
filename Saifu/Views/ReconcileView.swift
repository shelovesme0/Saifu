import SwiftUI

/// Sheet «Звірка»: скільки зараз у гаманці → бейдж різниці → підтвердження.
struct ReconcileView: View {
    @State private var viewModel: ReconcileViewModel
    @FocusState private var isAmountFocused: Bool

    init(viewModel: ReconcileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Очікується за записами")
                            .font(Theme.font(.subheadline))
                            .foregroundStyle(Theme.secondaryText)
                        Text(viewModel.expectedText)
                            .font(Theme.font(size: 30, weight: .bold))
                            .foregroundStyle(Theme.text)
                    }
                    .themedCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Скільки зараз у гаманці?")
                            .font(Theme.font(.subheadline, weight: .semibold))
                            .foregroundStyle(Theme.text)
                        AmountField(placeholder: "0", text: $viewModel.actualText, currency: viewModel.currency)
                            .focused($isAmountFocused)
                    }

                    if let badge = viewModel.badgeTitle, let outcome = viewModel.outcome {
                        VStack(alignment: .leading, spacing: 8) {
                            DifferenceBadge(title: badge, outcome: outcome)
                            if let detail = viewModel.differenceText {
                                Text(detail)
                                    .font(Theme.captionFont)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                        .transition(.scale(scale: 0.9, anchor: .leading).combined(with: .opacity))
                    }

                    if let message = viewModel.errorMessage {
                        Label(message, systemImage: "exclamationmark.circle")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.negative)
                    }

                    Button {
                        isAmountFocused = false
                        withAnimation(.snappy) { viewModel.confirm() }
                    } label: {
                        Text("Підтвердити")
                            .font(Theme.headlineFont)
                            .foregroundStyle(viewModel.outcome == nil ? Theme.secondaryText : Theme.text)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(viewModel.outcome == nil ? Theme.field : Theme.accent,
                                        in: RoundedRectangle(cornerRadius: Theme.fieldRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.outcome == nil)
                }
                .padding(Theme.gutter)
                .dismissKeyboardOnBackgroundTap { isAmountFocused = false }
                .animation(.spring(duration: 0.35), value: viewModel.badgeTitle)
                .animation(.snappy, value: viewModel.errorMessage)
            }
            .scrollDismissesKeyboard(.interactively)
            .themedScreen()
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.background)
        .presentationCornerRadius(Theme.bigCardRadius)
        .onAppear { isAmountFocused = true }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Звірка")
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.text)
                Text(viewModel.walletTitle)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Button { viewModel.cancel() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .frame(width: 36, height: 36)
                    .background(Theme.card, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Скасувати")
        }
        .padding(.top, 8)
    }
}

/// Бейдж різниці: колір і іконка залежать від стану звірки.
private struct DifferenceBadge: View {
    let title: String
    let outcome: ReconcileViewModel.Outcome

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .contentTransition(.symbolEffect(.replace))
            Text(title)
                .contentTransition(.numericText())
        }
        .font(Theme.font(.headline, weight: .semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(color.opacity(0.16), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 1))
    }

    private var color: Color {
        switch outcome {
        case .match: return Theme.match
        case .shortage: return Theme.shortage
        case .surplus: return Theme.surplus
        }
    }

    private var symbol: String {
        switch outcome {
        case .match: return "checkmark.circle.fill"
        case .shortage: return "arrow.down.circle.fill"
        case .surplus: return "arrow.up.circle.fill"
        }
    }
}

#Preview {
    let factory = ScreenFactory.preview()
    return factory.view(for: .reconcile(walletID: factory.previewWalletID))
        .preferredColorScheme(.dark)
}
