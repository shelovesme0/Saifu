import SwiftUI

/// Єдине місце стилю: кольори, радіуси, відступи, шрифти.
enum Theme {
    // MARK: Кольори
    static let background = Color(hex: 0x0B0B0D)
    static let card = Color(hex: 0x1C1C20)
    static let field = Color(hex: 0x2A2A30)
    static let text = Color.white
    static let secondaryText = Color(hex: 0xA9A9B3)
    static let accent = Color(hex: 0x8C7BFF)
    /// Від'ємний баланс.
    static let negative = Color(hex: 0xFF8A80)

    // Стани звірки
    static let match = Color(hex: 0x4CD98A)
    static let shortage = Color(hex: 0xFFA24C)
    static let surplus = Color(hex: 0x5AB0FF)

    // Градієнт картки гаманця
    static let cardBase = Color(hex: 0x2A2440)
    static let cardPink = Color(hex: 0xF2C6DE)
    static let cardViolet = Color(hex: 0x8C7BFF)
    static let cardPeach = Color(hex: 0xFFD3A8)

    // MARK: Радіуси
    static let cardRadius: CGFloat = 22
    static let bigCardRadius: CGFloat = 24
    static let fieldRadius: CGFloat = 13

    // MARK: Відступи
    static let gutter: CGFloat = 16
    static let spacing: CGFloat = 12
    static let cardPadding: CGFloat = 18
    /// Відступ від кіл до краю панелі вкладок.
    static let pillInset: CGFloat = 8
    static let pillItemSize: CGFloat = 48
    static let fieldHeight: CGFloat = 48
    static let compactFieldHeight: CGFloat = 40

    // MARK: Шрифти (системний .rounded)
    static func font(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }

    static func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let balanceFont = font(size: 40, weight: .bold)
    static let titleFont = font(.title2, weight: .bold)
    static let headlineFont = font(.headline, weight: .semibold)
    static let bodyFont = font(.body)
    static let captionFont = font(.caption)
}

extension Color {
    /// Колір з 0xRRGGBB.
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

extension View {
    /// Картка: фон Theme.card і великий радіус.
    func themedCard(padding: CGFloat = Theme.cardPadding) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }

    /// Поле вводу: фон Theme.field і менший радіус.
    func themedField(height: CGFloat = Theme.fieldHeight) -> some View {
        self
            .font(Theme.bodyFont)
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 14)
            .frame(height: height)
            .background(Theme.field, in: RoundedRectangle(cornerRadius: Theme.fieldRadius, style: .continuous))
    }

    /// Темний фон екрана на всю площу.
    func themedScreen() -> some View {
        self
            .background(Theme.background.ignoresSafeArea())
            .toolbarBackground(Theme.background, for: .navigationBar)
    }
}
