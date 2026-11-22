import SwiftUI

/// Рядок операції: заголовок, нотатка, сума кольором за знаком.
struct EntryRowView: View {
    let row: EntryRow

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(row.title)
                if let subtitle = row.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(row.amountText)
                .foregroundStyle(row.isNegative ? .red : .green)
        }
    }
}
