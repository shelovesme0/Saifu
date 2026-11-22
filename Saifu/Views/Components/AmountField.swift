import SwiftUI

/// Поле суми: недозволені символи прибираються одразу, навіть при вставці чи вводі з клавіатури Mac.
struct AmountField: View {
    let placeholder: String
    @Binding var text: String
    let currency: Currency

    var body: some View {
        HStack(spacing: 8) {
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Theme.secondaryText))
                .keyboardType(currency.minorUnits == 0 ? .numberPad : .decimalPad)
                .font(Theme.font(.title3, weight: .semibold))
                .onChange(of: text) { _, newValue in
                    let clean = AmountInputFilter.sanitize(newValue, currency: currency)
                    if clean != newValue {
                        text = clean
                    }
                }
            Text(currency.symbol)
                .font(Theme.font(.title3, weight: .semibold))
                .foregroundStyle(Theme.secondaryText)
        }
        .themedField()
    }
}
