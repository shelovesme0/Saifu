import SwiftUI

/// Рядок витрати: іконка категорії в колі, нотатка або назва категорії, категорія дрібно, сума.
struct ExpenseRowView: View {
    let row: EntryRow

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: row.symbolName)
                .font(Theme.font(.body, weight: .semibold))
                .foregroundStyle(row.tint)
                .frame(width: 42, height: 42)
                .background(row.tint.opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .font(Theme.font(.body, weight: .medium))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                if let subtitle = row.subtitle {
                    Text(subtitle)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.secondaryText)
                }
            }

            Spacer(minLength: 8)

            Text(row.amountText)
                .font(Theme.font(.body, weight: .semibold))
                .foregroundStyle(row.isNegative ? Theme.text : Theme.match)
                .contentTransition(.numericText())
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

private extension EntryRow {
    var tint: Color { category?.color ?? Theme.match }
}
