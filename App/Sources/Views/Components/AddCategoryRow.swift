//
//  AddCategoryRow.swift
//  Dawny
//
//  „Geister-Zeile“ zum Anlegen einer neuen Kategorie (Placeholder → aktives Textfeld).
//

import SwiftUI

struct AddCategoryRow: View {
    let onCreate: (String) -> Void

    @State private var isEditing = false
    @State private var draft = ""
    @FocusState private var isFocused: Bool

    private let maxLength = CategoryService.maxNameLength

    private var trimmed: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        !trimmed.isEmpty && trimmed.count <= maxLength
    }

    private var placeholder: String {
        String(localized: "category.add.placeholder", defaultValue: "New category")
    }

    var body: some View {
        Group {
            if isEditing {
                activeRow
            } else {
                ghostRow
            }
        }
    }

    private var ghostRow: some View {
        HStack {
            Image(systemName: "plus")
                .foregroundStyle(.secondary)
                .opacity(0.6)
                .frame(width: 20)

            Text(placeholder)
                .font(.headline)
                .foregroundStyle(.secondary)
                .opacity(0.6)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isEditing = true
            draft = ""
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(localized: "category.add.accessibility", defaultValue: "Add new category")
        )
        .accessibilityAddTraits(.isButton)
    }

    private var activeRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "tag")
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.accentColor.opacity(0.15))
                )

            TextField(placeholder, text: $draft)
                .font(.headline)
                .foregroundStyle(.primary)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
                .submitLabel(.done)
                .focused($isFocused)
                .onSubmit { submit() }

            Button {
                submit()
            } label: {
                Text(String(localized: "common.done", defaultValue: "Done"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isValid ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.borderless)
            .disabled(!isValid)
            .accessibilityLabel(String(localized: "common.done", defaultValue: "Done"))
        }
        .onAppear {
            HapticFeedback.light()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFocused = true
            }
        }
        .onChange(of: isFocused) { wasFocused, isNowFocused in
            guard wasFocused, !isNowFocused else { return }
            if isValid {
                submit()
            } else {
                cancel()
            }
        }
    }

    private func submit() {
        guard isValid else {
            HapticFeedback.error()
            return
        }
        onCreate(trimmed)
        resetAfterCreate()
    }

    private func cancel() {
        draft = ""
        isEditing = false
    }

    /// Zuerst `draft` leeren, dann Fokus entfernen – sonst feuert `onChange` noch mit altem Text und legt doppelt an.
    private func resetAfterCreate() {
        draft = ""
        isFocused = false
        isEditing = false
    }
}
