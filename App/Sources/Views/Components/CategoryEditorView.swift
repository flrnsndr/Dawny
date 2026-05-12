// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

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
        /// Creating a new category. Callback receives name, optional icon override, and recurring flag.
        case add(onCreate: (String, String?, Bool) -> Void)
        /// Editing an existing category. Callback receives the (possibly unchanged) values.
        case edit(Category, onSave: (String, String, Bool) -> Void)
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
        case .edit(let category, _):
            _name = State(initialValue: category.displayName)
            _pickedIconName = State(initialValue: category.displayIconName)
            _isRecurring = State(initialValue: category.isRecurring)
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
                Text(daysLabel(3)).tag(AutoArchiveOption.days3)
                Text(daysLabel(7)).tag(AutoArchiveOption.days7)
                Text(daysLabel(14)).tag(AutoArchiveOption.days14)
                Text(daysLabel(30)).tag(AutoArchiveOption.days30)
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
            Text(String(localized: "categoryEditor.autoArchive.section", defaultValue: "Auto-archive from backlog"))
        } footer: {
            if isRecurring {
                Text(
                    String(
                        localized: "categoryEditor.autoArchive.disabledFooter",
                        defaultValue: "Recurring categories never archive — tasks always return to the backlog."
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
            onCreate(trimmedName, pickedIconName, isRecurring)
        case .edit(_, let onSave):
            onSave(trimmedName, displayIconName, isRecurring)
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
    case off, days3, days7, days14, days30, days365, custom
}

// MARK: - Preview

#Preview("Add") {
    CategoryEditorView(mode: .add { name, icon, recurring in
        print("Add: \(name), icon: \(icon ?? "default"), recurring: \(recurring)")
    })
}

#Preview("Edit") {
    CategoryEditorView(mode: .edit(
        Category(
            categoryType: .custom,
            name: "Work",
            iconName: "briefcase.fill",
            isNameCustomized: true,
            isIconCustomized: true
        )
    ) { name, icon, recurring in
        print("Save: \(name), icon: \(icon), recurring: \(recurring)")
    })
}
