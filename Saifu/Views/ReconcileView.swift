import SwiftUI

/// Sheet «Звірка»: скільки зараз у гаманці → різниця → підтвердження.
struct ReconcileView: View {
    @State private var viewModel: ReconcileViewModel

    init(viewModel: ReconcileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(viewModel.walletTitle) {
                    LabeledContent("Очікується", value: viewModel.expectedText)
                    TextField("Скільки зараз у гаманці?", text: $viewModel.actualText)
                        .keyboardType(.decimalPad)
                }

                if let text = viewModel.differenceText {
                    Section("Різниця") {
                        Text(text)
                            .foregroundStyle(color(for: viewModel.outcome))
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if let message = viewModel.errorMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(.red)
                    }
                }
            }
            .animation(.default, value: viewModel.differenceText)
            .animation(.default, value: viewModel.errorMessage)
            .navigationTitle("Звірка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { viewModel.cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Підтвердити") { viewModel.confirm() }
                        .disabled(viewModel.differenceText == nil)
                }
            }
        }
    }

    private func color(for outcome: ReconcileViewModel.Outcome?) -> Color {
        switch outcome {
        case .shortage: return .red
        case .surplus: return .green
        case .match, nil: return .primary
        }
    }
}

#Preview {
    let factory = ScreenFactory.preview()
    return factory.view(for: .reconcile(walletID: factory.previewWalletID))
}
