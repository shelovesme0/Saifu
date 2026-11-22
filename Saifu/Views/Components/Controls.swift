import SwiftUI

/// Кнопка «назад» у стилі застосунку.
struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.text)
                .frame(width: 40, height: 40)
                .background(Theme.card, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Назад")
    }
}

/// Індикатор сторінок: активна крапка витягнута біла, інші — сірі.
struct PageDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Color.white : Theme.secondaryText.opacity(0.4))
                    .frame(width: i == index ? 20 : 7, height: 7)
            }
        }
        .animation(.snappy, value: index)
    }
}

extension View {
    /// Тап по порожньому місцю (між полями й картками) закриває клавіатуру.
    func dismissKeyboardOnBackgroundTap(_ action: @escaping () -> Void) -> some View {
        background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: action)
        }
    }
}
