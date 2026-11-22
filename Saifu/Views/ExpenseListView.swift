import SwiftUI

/// Усі витрати гаманця: підсумок за фільтром, чипи категорій, список за днями.
struct ExpenseListView: View {
    @State private var viewModel: ExpenseListViewModel

    init(viewModel: ExpenseListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(title: "Усі витрати", subtitle: viewModel.title) {
                    viewModel.backTapped()
                }

                totalCard

                ChipPicker(options: [nil] + viewModel.categoryOptions.map(Optional.some),
                           selection: $viewModel.selectedCategory,
                           title: { $0?.title ?? "Усі" },
                           symbol: { $0?.symbolName })

                if viewModel.isEmpty {
                    Text("Витрат немає")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }

                ForEach(viewModel.sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(Theme.font(.subheadline, weight: .semibold))
                            .foregroundStyle(Theme.secondaryText)
                            .padding(.leading, 4)
                        VStack(spacing: 0) {
                            ForEach(section.rows) { row in
                                Button { viewModel.rowTapped(row) } label: {
                                    ExpenseRowView(row: row)
                                }
                                .buttonStyle(.plain)
                                .transition(.opacity)
                            }
                        }
                        .themedCard(padding: 12)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 32)
        }
        .animation(.snappy, value: viewModel.sections)
        .themedScreen()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var totalCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Разом за фільтром")
                .font(Theme.font(.subheadline))
                .foregroundStyle(Theme.secondaryText)
            Text(viewModel.totalText)
                .font(Theme.font(size: 30, weight: .bold))
                .foregroundStyle(Theme.text)
                .contentTransition(.numericText())
            Text(viewModel.countText)
                .font(Theme.captionFont)
                .foregroundStyle(Theme.secondaryText)
                .contentTransition(.numericText())
        }
        .themedCard()
        .animation(.snappy, value: viewModel.totalText)
    }
}

/// Заголовок вкладеного екрана з кнопкою «назад».
struct ScreenHeader: View {
    let title: String
    var subtitle: String?
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            BackButton(action: onBack)
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
        }
        .padding(.top, 8)
    }
}

#Preview {
    let factory = ScreenFactory.preview()
    return NavigationStack {
        factory.view(for: .expenseList(walletID: factory.previewWalletID))
    }
    .preferredColorScheme(.dark)
}
