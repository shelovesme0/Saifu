import SwiftUI

/// Стан курсу валют: курс / завантаження / повідомлення про помилку з кнопкою «Повторити».
struct RateStatusView: View {
    let state: LoadState
    /// Текст курсу для стану `.loaded`; nil — курсу для цієї валюти немає.
    var rateText: String?
    /// Вузьке місце (поруч із діаграмою): коротші підписи, кнопка під текстом.
    var compact = false
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .idle, .loading:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .tint(Theme.secondaryText)
                Text(compact ? "Курс…" : "Завантажуємо курс НБУ…")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
        case .loaded:
            if let rateText {
                Label(rateText, systemImage: "arrow.left.arrow.right")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                message("Курс для цієї валюти недоступний.", systemImage: "questionmark.circle", color: Theme.secondaryText)
            }
        case .empty:
            message(LoadState.emptyRatesMessage, systemImage: "calendar.badge.exclamationmark", color: Theme.secondaryText)
        case .failed(let text):
            message(text, systemImage: "exclamationmark.triangle", color: Theme.shortage)
        }
    }

    private func message(_ text: String, systemImage: String, color: Color) -> some View {
        let layout = compact
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 10))
        return layout {
            Label(text, systemImage: systemImage)
                .font(Theme.captionFont)
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
            if !compact { Spacer(minLength: 0) }
            Button(action: onRetry) {
                Label("Повторити", systemImage: "arrow.clockwise")
                    .font(Theme.font(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(Theme.field, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        RateStatusView(state: .loading) {}
        RateStatusView(state: .loaded, rateText: "1 ¥ = 0,28336 ₴ · НБУ, 24.11.2026") {}
        RateStatusView(state: .empty) {}
        RateStatusView(state: .failed("Немає з'єднання з інтернетом. Перевірте мережу й повторіть.")) {}
        RateStatusView(state: .failed("Сервер НБУ повернув помилку (код 503)."), compact: true) {}
    }
    .padding()
    .background(Theme.background)
}
