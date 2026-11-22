import SwiftUI

/// Sheet «Період»: дати «з» і «по» для аналітики; «з» не може бути пізніше «по».
struct AnalyticsPeriodView: View {
    @Bindable var viewModel: AnalyticsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SheetHeader(title: "Період", subtitle: viewModel.selectedWalletTitle) {
                    viewModel.cancelCustomPeriod()
                }

                VStack(spacing: 0) {
                    DatePicker("З", selection: $viewModel.draftStart, displayedComponents: .date)
                        .padding(.vertical, 8)
                    Divider().overlay(Theme.field)
                    DatePicker("По", selection: $viewModel.draftEnd, displayedComponents: .date)
                        .padding(.vertical, 8)
                }
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.text)
                .tint(Theme.accent)
                .environment(\.locale, Locale(identifier: "uk_UA"))
                .themedCard(padding: 16)

                if let error = viewModel.draftError {
                    Label(error, systemImage: "exclamationmark.circle")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.negative)
                        .transition(.opacity)
                }

                PrimaryButton(title: "Застосувати", isEnabled: viewModel.draftError == nil) {
                    withAnimation(.snappy) { viewModel.applyCustomPeriod() }
                }
            }
            .padding(Theme.gutter)
            .animation(.snappy, value: viewModel.draftError)
        }
        .background(Theme.background.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.background)
        .presentationCornerRadius(Theme.bigCardRadius)
        .preferredColorScheme(.dark)
    }
}

/// Заголовок sheet: назва, підзаголовок і кнопка закриття.
struct SheetHeader: View {
    let title: String
    var subtitle: String?
    let onClose: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.text)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            Spacer()
            Button(action: onClose) {
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

/// Основна кнопка з акцентним фоном; неактивна — сіра.
struct PrimaryButton: View {
    let title: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.headlineFont)
                .foregroundStyle(isEnabled ? Theme.text : Theme.secondaryText)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(isEnabled ? Theme.accent : Theme.field,
                            in: RoundedRectangle(cornerRadius: Theme.fieldRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    let factory = ScreenFactory.preview()
    return factory.view(for: .analyticsPeriod)
}
