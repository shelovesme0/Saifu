import SwiftUI
import Charts

/// Аналітика: діаграма витрат за категоріями і сітка карток категорій.
struct AnalyticsView: View {
    @Bindable var viewModel: AnalyticsViewModel

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Аналітика")
                        .font(Theme.font(size: 34, weight: .bold))
                        .foregroundStyle(Theme.text)
                    Spacer()
                }
                .padding(.top, 8)

                walletMenu

                ChipPicker(options: AnalyticsViewModel.Period.allCases,
                           selection: periodBinding,
                           title: \.title)

                if viewModel.stats.isEmpty {
                    emptyState
                } else {
                    chartCard
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.stats) { stat in
                            CategoryStatCard(stat: stat)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 16)
            .animation(.snappy, value: viewModel.stats)
        }
        .themedScreen()
        .toolbar(.hidden, for: .navigationBar)
    }

    /// Випадаюче меню «Єни · JPY ▾».
    private var walletMenu: some View {
        Menu {
            ForEach(viewModel.walletOptions) { option in
                Button {
                    viewModel.selectWallet(option.id)
                } label: {
                    if option.id == viewModel.selectedOptionID {
                        Label(option.title, systemImage: "checkmark")
                    } else {
                        Text(option.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(viewModel.selectedWalletTitle)
                    .font(Theme.font(.headline, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(Theme.card, in: Capsule())
        }
    }

    /// Вибір чипа йде через ViewModel: «Період…» відкриває sheet із датами.
    private var periodBinding: Binding<AnalyticsViewModel.Period> {
        Binding(get: { viewModel.period },
                set: { viewModel.selectPeriod($0) })
    }

    private var chartCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Chart(viewModel.stats) { stat in
                    SectorMark(angle: .value("Сума", stat.amount),
                               innerRadius: .ratio(0.66),
                               angularInset: 2)
                        .cornerRadius(5)
                        .foregroundStyle(stat.category.color)
                }
                .chartLegend(.hidden)

                VStack(spacing: 2) {
                    Text(viewModel.totalText)
                        .font(Theme.font(.headline, weight: .bold))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .contentTransition(.numericText())
                    Text(viewModel.periodCaption)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 28)
            }
            .frame(width: 170, height: 170)

            VStack(alignment: .leading, spacing: 14) {
                if let converted = viewModel.convertedTotalText {
                    infoBlock(caption: viewModel.convertedCaption, value: converted)
                }
                if let top = viewModel.topCategory {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Найбільше")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.secondaryText)
                        // Назва не ламається посеред слова: до 2 рядків по словах, за потреби менший шрифт
                        Label(top.category.title, systemImage: top.category.symbolName)
                            .font(Theme.font(.subheadline, weight: .semibold))
                            .foregroundStyle(top.category.color)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(top.amountText) · \(top.percentText)")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.text)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .themedCard()
    }

    private func infoBlock(caption: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(caption)
                .font(Theme.captionFont)
                .foregroundStyle(Theme.secondaryText)
            Text(value)
                .font(Theme.font(.subheadline, weight: .semibold))
                .foregroundStyle(Theme.text)
                .contentTransition(.numericText())
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
            Text("Витрат за період немає")
                .font(Theme.headlineFont)
        }
        .foregroundStyle(Theme.secondaryText)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .themedCard()
    }
}

/// Картка категорії: кольорова мітка, назва, сума, відсоток, кількість витрат.
private struct CategoryStatCard: View {
    let stat: CategoryStat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(stat.category.color)
                    .frame(width: 10, height: 10)
                    .padding(.top, 5)
                // Довгі назви («Магазин біля дому») переносяться на другий рядок
                Text(stat.category.title)
                    .font(Theme.font(.subheadline, weight: .medium))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minHeight: 36, alignment: .topLeading)
            Text(stat.amountText)
                .font(Theme.font(.title3, weight: .bold))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
            HStack {
                Text(stat.percentText)
                    .foregroundStyle(stat.category.color)
                Spacer()
                Text(stat.countText)
                    .foregroundStyle(Theme.secondaryText)
            }
            .font(Theme.captionFont)
        }
        .themedCard(padding: 14)
    }
}

#Preview {
    ScreenFactory.preview().analyticsView()
        .preferredColorScheme(.dark)
}
