import SwiftUI

/// Вибір категорії для форм додавання й редагування.
struct CategoryPicker: View {
    @Binding var selection: ExpenseCategory?

    var body: some View {
        Picker("Категорія", selection: $selection) {
            Text("— оберіть —").tag(ExpenseCategory?.none)
            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                Text("\(category.emoji) \(category.title)").tag(ExpenseCategory?.some(category))
            }
        }
    }
}
