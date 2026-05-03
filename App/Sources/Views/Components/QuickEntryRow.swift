// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  QuickEntryRow.swift
//  Dawny
//
//  Inline „Geister-Zeile“ für schnelles Task-Anlegen (Continuous Entry).
//

import SwiftUI

struct QuickEntryRow: View {
    let placeholder: String
    /// Anzeigename der Kategorie (nur für Accessibility).
    let categoryAccessibilityName: String?
    /// Für `ScrollViewReader.scrollTo(_:anchor:)`.
    let scrollID: AnyHashable

    let onSubmit: (String) -> Void
    /// Wird aufgerufen, wenn sich die Tastatur-Fokussierung ändert (für Auto-Scroll).
    var onFocusChange: ((Bool) -> Void)?

    private let maxLength = 150

    @FocusState private var fieldFocused: Bool
    @State private var draft = ""

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasMeaningfulDraft: Bool {
        !trimmedDraft.isEmpty
    }

    var body: some View {
        rowContent
    }

    private var rowContent: some View {
        HStack(spacing: 10) {
            TextField(placeholder, text: $draft, axis: .vertical)
                .lineLimit(1...3)
                .font(.callout)
                .foregroundStyle(textFieldForeground)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
                .submitLabel(.return)
                .focused($fieldFocused)
                .onSubmit { commitFromUser() }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            fieldFocused = true
        }
        .id(scrollID)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityValue(accessibilityValueText)
        .accessibilityHint(String(localized: "quickentry.accessibility.hint", defaultValue: "Double-tap to edit the draft or create a task."))
        .accessibilityAddTraits(.isButton)
        .onChange(of: draft) { _, newValue in
            if newValue.count > maxLength {
                draft = String(newValue.prefix(maxLength))
                HapticFeedback.error()
                return
            }
            if let newlineRange = newValue.range(of: "\n") {
                draft = String(newValue[..<newlineRange.lowerBound])
                commitFromUser()
            }
        }
        .onChange(of: fieldFocused) { _, newValue in
            onFocusChange?(newValue)
        }
    }

    private var textFieldForeground: Color {
        if trimmedDraft.isEmpty && !fieldFocused {
            return Color.primary.opacity(0.45)
        }
        return .primary
    }

    private var accessibilityLabelText: String {
        if let categoryAccessibilityName {
            let format = String(
                localized: "quickentry.accessibility.add",
                defaultValue: "Add new task in %@"
            )
            return String(format: format, categoryAccessibilityName)
        } else {
            return String(
                localized: "quickentry.accessibility.addToday",
                defaultValue: "Add new task for today"
            )
        }
    }

    private var accessibilityValueText: String {
        hasMeaningfulDraft ? trimmedDraft : ""
    }

    private func commitFromUser() {
        if trimmedDraft.isEmpty {
            fieldFocused = false
            return
        }
        let title = trimmedDraft
        draft = ""
        onSubmit(title)
        HapticFeedback.success()
    }
}
