import SwiftUI

/// Вибір категорії меню з SF Symbols.
struct CategoryMenu: View {
    @Binding var selection: ExpenseCategory?
    /// Компактна кнопка для рядка поруч з нотаткою: лише назва й chevron.
    var compact = false

    var body: some View {
        Menu {
            Picker("Категорія", selection: $selection) {
                ForEach(ExpenseCategory.allCases, id: \.self) { category in
                    Label(category.title, systemImage: category.symbolName)
                        .tag(ExpenseCategory?.some(category))
                }
            }
        } label: {
            if compact {
                compactLabel
            } else {
                fullLabel
            }
        }
    }

    private var compactLabel: some View {
        HStack(spacing: 6) {
            if let selection {
                Image(systemName: selection.symbolName)
                    .foregroundStyle(selection.color)
            }
            Text(selection?.title ?? "Категорія")
                .foregroundStyle(selection == nil ? Theme.secondaryText : Theme.text)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.secondaryText)
        }
        .font(Theme.font(.subheadline, weight: .medium))
        .padding(.horizontal, 12)
        .frame(height: Theme.compactFieldHeight)
        .background(Theme.field, in: RoundedRectangle(cornerRadius: Theme.fieldRadius, style: .continuous))
        .contentShape(Rectangle())
        .fixedSize(horizontal: true, vertical: false)
    }

    private var fullLabel: some View {
        HStack(spacing: 10) {
            Image(systemName: selection?.symbolName ?? "square.grid.2x2")
                .foregroundStyle(selection?.color ?? Theme.secondaryText)
                .frame(width: 22)
            Text(selection?.title ?? "Категорія")
                .foregroundStyle(selection == nil ? Theme.secondaryText : Theme.text)
                .lineLimit(1)
            Spacer(minLength: 4)
            Image(systemName: "chevron.up.chevron.down")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.secondaryText)
        }
        .themedField()
        .contentShape(Rectangle())
    }
}
