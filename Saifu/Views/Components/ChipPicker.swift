import SwiftUI

/// Горизонтальний ряд чипів: активний білий з темним текстом, решта — на фоні картки.
struct ChipPicker<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let title: (Value) -> String
    var symbol: (Value) -> String? = { _ in nil }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isActive = option == selection
                    Button {
                        withAnimation(.snappy) { selection = option }
                    } label: {
                        HStack(spacing: 6) {
                            if let name = symbol(option) {
                                Image(systemName: name)
                            }
                            Text(title(option))
                        }
                        .font(Theme.font(.subheadline, weight: .semibold))
                        .foregroundStyle(isActive ? Theme.background : Theme.text)
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(isActive ? Color.white : Theme.card, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollClipDisabled()
    }
}
