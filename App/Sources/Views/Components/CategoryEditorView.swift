// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  CategoryEditorView.swift
//  Dawny
//
//  Modal sheet for creating and editing categories.
//

import SwiftUI

struct CategoryEditorView: View {

    // MARK: - Mode

    enum Mode {
        /// Creating a new category. Callback receives name, optional icon override, recurring flag, and auto-archive days.
        case add(onCreate: (String, String?, Bool, Int?) -> Void)
        /// Editing an existing category. Callback receives the (possibly unchanged) values.
        case edit(Category, onSave: (String, String, Bool, Int?) -> Void)
    }

    // MARK: - Properties

    let mode: Mode

    @State private var name: String
    /// Nil in add-mode until the user explicitly picks an icon.
    @State private var pickedIconName: String?
    @State private var isRecurring: Bool
    @State private var autoArchive: AutoArchiveOption = .off
    @State private var autoArchiveCustomDays: Int = 7
    @State private var autoArchiveCustomText: String = "7"

    @State private var showingIconPicker = false
    @FocusState private var isNameFocused: Bool
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add:
            _name = State(initialValue: "")
            _pickedIconName = State(initialValue: nil)
            _isRecurring = State(initialValue: false)
            _autoArchive = State(initialValue: .days365)
            _autoArchiveCustomDays = State(initialValue: 365)
            _autoArchiveCustomText = State(initialValue: "365")
        case .edit(let category, _):
            _name = State(initialValue: category.displayName)
            _pickedIconName = State(initialValue: category.displayIconName)
            _isRecurring = State(initialValue: category.isRecurring)
            let (option, customDays) = AutoArchiveOption.from(days: category.autoArchiveDays)
            _autoArchive = State(initialValue: option)
            _autoArchiveCustomDays = State(initialValue: customDays)
            _autoArchiveCustomText = State(initialValue: "\(customDays)")
        }
    }

    // MARK: - Computed

    private var isAddMode: Bool {
        if case .add = mode { return true }
        return false
    }

    private var displayIconName: String {
        pickedIconName ?? "tag"
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        !trimmedName.isEmpty && trimmedName.count <= CategoryService.maxNameLength
    }

    private var selectedAutoArchiveDays: Int? {
        isRecurring ? nil : autoArchive.days(customDays: autoArchiveCustomDays)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                nameIconSection
                recurringSection
                autoArchiveSection
            }
            .navigationTitle(
                isAddMode
                    ? String(localized: "categoryEditor.title.add", defaultValue: "New Category")
                    : String(localized: "categoryEditor.title.edit", defaultValue: "Edit Category")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "quickadd.cancel", defaultValue: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(
                        isAddMode
                            ? String(localized: "categoryEditor.button.add", defaultValue: "Add")
                            : String(localized: "categoryEditor.button.save", defaultValue: "Save")
                    ) {
                        submit()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                CategorySymbolPicker(currentSymbol: displayIconName) { newSymbol in
                    pickedIconName = newSymbol
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    isNameFocused = true
                }
            }
            .onChange(of: isRecurring) { _, newValue in
                if newValue { autoArchive = .off }
            }
        }
    }

    // MARK: - Sections

    private var nameIconSection: some View {
        Section {
            HStack(spacing: 12) {
                Button {
                    HapticFeedback.light()
                    showingIconPicker = true
                } label: {
                    Image(systemName: displayIconName)
                        .font(.title3)
                        .frame(width: 36, height: 36)
                        .foregroundStyle(Color.accentColor)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.accentColor.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    String(localized: "categoryEditor.iconButton.accessibility", defaultValue: "Choose icon")
                )

                TextField(
                    String(localized: "categoryEditor.namePlaceholder", defaultValue: "Category name"),
                    text: $name
                )
                .font(.headline)
                .textInputAutocapitalization(.sentences)
                .focused($isNameFocused)
                .submitLabel(.done)
                .onSubmit { if isValid { submit() } }
            }
        }
    }

    private var recurringSection: some View {
        Section {
            Toggle(
                String(localized: "categoryEditor.recurring.title", defaultValue: "Recurring tasks"),
                isOn: $isRecurring
            )
        } footer: {
            Text(
                String(
                    localized: "categoryEditor.recurring.footer",
                    defaultValue: "Tasks reappear in the backlog right after you complete or archive them."
                )
            )
        }
    }

    private var autoArchiveSection: some View {
        Section {
            Picker(
                String(localized: "categoryEditor.autoArchive.after", defaultValue: "After"),
                selection: $autoArchive
            ) {
                Text(String(localized: "categoryEditor.autoArchive.option.off", defaultValue: "Off"))
                    .tag(AutoArchiveOption.off)
                Text(daysLabel(7)).tag(AutoArchiveOption.days7)
                Text(daysLabel(30)).tag(AutoArchiveOption.days30)
                Text(daysLabel(90)).tag(AutoArchiveOption.days90)
                Text(daysLabel(365)).tag(AutoArchiveOption.days365)
                Text(
                    String(localized: "categoryEditor.autoArchive.option.custom", defaultValue: "Custom…")
                ).tag(AutoArchiveOption.custom)
            }
            .pickerStyle(.menu)

            if autoArchive == .custom {
                HStack {
                    TextField("", text: $autoArchiveCustomText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity)
                        .onChange(of: autoArchiveCustomText) { _, newValue in
                            let digits = newValue.filter(\.isNumber)
                            let clamped = min(max(Int(digits) ?? 1, 1), 365)
                            autoArchiveCustomDays = clamped
                            autoArchiveCustomText = digits.isEmpty ? "" : "\(clamped)"
                        }
                    Text(String(localized: "categoryEditor.autoArchive.daysUnit", defaultValue: "days"))
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text(String(localized: "categoryEditor.autoArchive.section", defaultValue: "Auto-Tidy"))
        } footer: {
            if isRecurring {
                Text(
                    String(
                        localized: "categoryEditor.autoArchive.disabledFooter",
                        defaultValue: "Recurring categories never archive — tasks always return to the backlog."
                    )
                )
            } else if autoArchive != .off {
                Text(
                    String(
                        localized: "categoryEditor.autoArchive.enabledFooter",
                        defaultValue: "After this many days in the backlog, tasks move to the Archive. The countdown resets every time you pull a task into Today."
                    )
                )
            }
        }
        .disabled(isRecurring)
    }

    // MARK: - Actions

    private func submit() {
        guard isValid else {
            HapticFeedback.error()
            return
        }
        switch mode {
        case .add(let onCreate):
            onCreate(trimmedName, pickedIconName, isRecurring, selectedAutoArchiveDays)
        case .edit(_, let onSave):
            onSave(trimmedName, displayIconName, isRecurring, selectedAutoArchiveDays)
        }
        dismiss()
    }

    private func daysLabel(_ days: Int) -> String {
        let fmt = String(localized: "categoryEditor.autoArchive.daysFormat", defaultValue: "%d days")
        return String(format: fmt, days)
    }
}

// MARK: - AutoArchiveOption

private enum AutoArchiveOption: Hashable {
    case off, days7, days30, days90, days365, custom

    func days(customDays: Int) -> Int? {
        switch self {
        case .off: nil
        case .days7: 7
        case .days30: 30
        case .days90: 90
        case .days365: 365
        case .custom: customDays
        }
    }

    static func from(days: Int?) -> (AutoArchiveOption, Int) {
        switch days {
        case nil: return (.off, 7)
        case 7: return (.days7, 7)
        case 30: return (.days30, 30)
        case 90: return (.days90, 90)
        case 365: return (.days365, 365)
        default:
            let clamped = max(1, min(days ?? 7, 365))
            return (.custom, clamped)
        }
    }
}

// MARK: - Preview

#Preview("Add") {
    CategoryEditorView(mode: .add { name, icon, recurring, days in
        print("Add: \(name), icon: \(icon ?? "default"), recurring: \(recurring), days: \(String(describing: days))")
    })
}

#Preview("Edit") {
    CategoryEditorView(mode: .edit(
        Category(
            categoryType: .custom,
            name: "Work",
            iconName: "briefcase.fill",
            isNameCustomized: true,
            isIconCustomized: true,
            autoArchiveDays: 21
        )
    ) { name, icon, recurring, days in
        print("Save: \(name), icon: \(icon), recurring: \(recurring), days: \(String(describing: days))")
    })
}
