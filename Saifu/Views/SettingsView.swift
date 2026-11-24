import SwiftUI
import UniformTypeIdentifiers

/// Налаштування: керування гаманцями, домашня валюта, нагадування, резервна копія, версія.
struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @Bindable var backup: BackupViewModel

    var body: some View {
        List {
            Section {
                Text("Налаштування")
                    .font(Theme.font(size: 34, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 0, trailing: 0))
            }

            walletsSection
            currencySection
            reminderSection
            backupSection
            #if DEBUG
            developerSection
            #endif

            Section(header: header("Про застосунок")) {
                HStack {
                    Label("Версія", systemImage: "info.circle")
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Text(viewModel.appVersion)
                        .foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.card)
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(18)
        .scrollContentBackground(.hidden)
        .font(Theme.bodyFont)
        .animation(.snappy, value: viewModel.isReminderEnabled)
        .animation(.snappy, value: viewModel.reminderMessage)
        .animation(.snappy, value: backup.isAutoBackupEnabled)
        .animation(.snappy, value: backup.isFolderUnavailable)
        .animation(.snappy, value: backup.message)
        // Один пікер на екран і для папки, і для файлу: два .fileImporter на одному view конфліктують
        .fileImporter(isPresented: $backup.isPickerPresented,
                      allowedContentTypes: backup.pickerMode == .folder ? [.folder] : [.json]) { result in
            backup.pickerFinished(result)
        }
        .fileExporter(isPresented: $backup.isExporterPresented,
                      document: backup.exportDocument,
                      contentType: .json,
                      defaultFilename: backup.exportFileName) { result in
            backup.exportFinished(result)
        }
        .confirmationDialog("Імпортувати резервну копію?",
                            isPresented: $backup.isConfirmingImport,
                            titleVisibility: .visible) {
            Button("Замінити", role: .destructive) { backup.confirmImport() }
            Button("Скасувати", role: .cancel) {}
        } message: {
            Text("Поточні дані буде замінено. Перед цим буде збережено їхню копію")
        }
        .themedScreen()
        .toolbar(.hidden, for: .navigationBar)
    }

    /// Один рядок: відкриває той самий sheet «Гаманці», що й кнопка на головній.
    private var walletsSection: some View {
        Section {
            Button { viewModel.manageWalletsTapped() } label: {
                HStack {
                    Label("Керувати гаманцями", systemImage: "wallet.pass")
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.secondaryText)
                }
                .contentShape(Rectangle())
            }
            .listRowBackground(Theme.card)
        } header: {
            header("Гаманці")
        }
    }

    private var currencySection: some View {
        Section {
            Picker(selection: $viewModel.homeCurrency) {
                ForEach(Currency.allCases, id: \.self) { currency in
                    Text("\(currency.code) \(currency.symbol)").tag(currency)
                }
            } label: {
                Label("Домашня валюта", systemImage: "house")
                    .foregroundStyle(Theme.text)
            }
            .pickerStyle(.menu)
            .tint(Theme.accent)
            .listRowBackground(Theme.card)
        } header: {
            header("Валюта")
        } footer: {
            Text("У ній показується «≈ …» на картках гаманців і в аналітиці.")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private var reminderSection: some View {
        Section {
            Toggle(isOn: reminderBinding) {
                Label("Нагадувати звірити гаманець", systemImage: "bell.badge")
                    .foregroundStyle(Theme.text)
            }
            .tint(Theme.accent)
            .listRowBackground(Theme.card)

            if viewModel.isReminderEnabled {
                Picker(selection: intervalBinding) {
                    ForEach(ReminderInterval.allCases, id: \.self) { interval in
                        Text(interval.title).tag(interval)
                    }
                } label: {
                    Label("Як часто", systemImage: "clock.arrow.circlepath")
                        .foregroundStyle(Theme.text)
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
                .listRowBackground(Theme.card)

                DatePicker(selection: timeBinding, displayedComponents: .hourAndMinute) {
                    Label("Час", systemImage: "clock")
                        .foregroundStyle(Theme.text)
                }
                .tint(Theme.accent)
                .environment(\.locale, Locale(identifier: "uk_UA"))
                .listRowBackground(Theme.card)
            }
        } header: {
            header("Нагадування")
        } footer: {
            if let message = viewModel.reminderMessage {
                Text(message)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.shortage)
            }
        }
    }

    private var backupSection: some View {
        Section {
            Toggle(isOn: autoBackupBinding) {
                Label("Автоматична резервна копія", systemImage: "externaldrive.badge.timemachine")
                    .foregroundStyle(Theme.text)
            }
            .tint(Theme.accent)
            .listRowBackground(Theme.card)

            if backup.isAutoBackupEnabled {
                if backup.isFolderUnavailable {
                    Label("Немає доступу до папки копій. Можливо, її видалили або перемістили",
                          systemImage: "exclamationmark.triangle")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.shortage)
                        .listRowBackground(Theme.card)
                    rowButton("Вибрати папку знову", systemImage: "folder.badge.questionmark") {
                        backup.chooseFolderAgainTapped()
                    }
                } else if let folderName = backup.folderName {
                    HStack {
                        Label("Папка", systemImage: "folder")
                            .foregroundStyle(Theme.text)
                        Spacer()
                        Text(folderName)
                            .foregroundStyle(Theme.secondaryText)
                            .lineLimit(1)
                    }
                    .listRowBackground(Theme.card)
                }
            }

            rowButton("Експортувати зараз", systemImage: "square.and.arrow.up") {
                backup.exportTapped()
            }
            rowButton("Імпортувати", systemImage: "square.and.arrow.down") {
                backup.importTapped()
            }
        } header: {
            header("Резервна копія")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Зберігайте копії в iCloud Drive, щоб вони пережили видалення застосунку")
                    .foregroundStyle(Theme.secondaryText)
                Text(backup.lastBackupText)
                    .foregroundStyle(Theme.secondaryText)
                if let message = backup.message {
                    Text(message.text)
                        .foregroundStyle(message.isError ? Theme.shortage : Theme.match)
                }
            }
            .font(Theme.captionFont)
        }
    }

    private func rowButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .listRowBackground(Theme.card)
    }

    /// Тумблер викликає ViewModel: увімкнення спершу відкриває вибір папки.
    private var autoBackupBinding: Binding<Bool> {
        Binding(get: { backup.isAutoBackupEnabled },
                set: { backup.setAutoBackup($0) })
    }

    #if DEBUG
    /// Лише Debug: джерело курсів, щоб показати всі стани завантаження. У Release секції немає.
    private var developerSection: some View {
        Section {
            Picker(selection: $viewModel.rateSourceMode) {
                ForEach(RateSourceMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            } label: {
                Label("Джерело курсів", systemImage: "antenna.radiowaves.left.and.right")
                    .foregroundStyle(Theme.text)
            }
            .pickerStyle(.menu)
            .tint(Theme.accent)
            .listRowBackground(Theme.card)
        } header: {
            header("Розробка")
        } footer: {
            Text("Лише в Debug-збірці. Режими mock працюють без мережі; після вибору курс завантажується наново.")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.secondaryText)
        }
    }
    #endif

    /// Тумблер викликає ViewModel; вона сама вирішує, чи лишити його увімкненим (дозвіл).
    private var reminderBinding: Binding<Bool> {
        Binding(get: { viewModel.isReminderEnabled },
                set: { enabled in Task { await viewModel.setReminderEnabled(enabled) } })
    }

    private var timeBinding: Binding<Date> {
        Binding(get: { viewModel.reminderTimeDate },
                set: { date in Task { await viewModel.setReminderTime(date) } })
    }

    private var intervalBinding: Binding<ReminderInterval> {
        Binding(get: { viewModel.reminderInterval },
                set: { interval in Task { await viewModel.setReminderInterval(interval) } })
    }

    private func header(_ title: String) -> some View {
        Text(title)
            .font(Theme.font(.subheadline, weight: .semibold))
            .foregroundStyle(Theme.secondaryText)
            .textCase(nil)
    }
}

#Preview {
    RootView(factory: .preview())
}
