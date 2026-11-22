import SwiftUI

/// Усі витрати гаманця з фільтром за категорією.
struct ExpenseListView: View {
    @State private var viewModel: ExpenseListViewModel

    init(viewModel: ExpenseListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Picker("Категорія", selection: $viewModel.selectedCategory) {
                    Text("Усі").tag(ExpenseCategory?.none)
                    ForEach(viewModel.categoryOptions, id: \.self) { category in
                        Text("\(category.emoji) \(category.title)").tag(ExpenseCategory?.some(category))
                    }
                }
                .pickerStyle(.menu)
                LabeledContent("Разом", value: viewModel.totalText)
                    .contentTransition(.numericText())
            }

            Section {
                ForEach(viewModel.rows) { row in
                    EntryRowView(row: row)
                }
            }
        }
        .overlay {
            if viewModel.rows.isEmpty {
                ContentUnavailableView("Витрат немає", systemImage: "tray")
            }
        }
        .animation(.default, value: viewModel.rows)
        .animation(.default, value: viewModel.totalText)
        .navigationTitle(viewModel.title)
    }
}

#Preview {
    let factory = ScreenFactory.preview()
    return NavigationStack {
        factory.view(for: .expenseList(walletID: factory.previewWalletID))
    }
}
