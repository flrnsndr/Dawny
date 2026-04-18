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
                .submitLabel(.next)
                .focused($fieldFocused)
                .onSubmit { commitFromUser() }

            if fieldFocused {
                Button {
                    commitFromUser()
                } label: {
                    Image(systemName: "arrow.turn.down.left")
                        .font(.subheadline.weight(.semibold))
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(canCommit ? Color.accentColor : Color.secondary)
                        .frame(minWidth: 28, minHeight: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .disabled(!canCommit)
                .accessibilityLabel(
                    String(localized: "quickentry.submit.accessibility", defaultValue: "Bestätigen wie Eingabetaste")
                )
            }
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
        .accessibilityHint(String(localized: "quickentry.accessibility.hint", defaultValue: "Doppeltippen, um den Entwurf zu bearbeiten oder eine Aufgabe anzulegen."))
        .accessibilityAddTraits(.isButton)
        .onChange(of: fieldFocused) { _, newValue in
            onFocusChange?(newValue)
        }
    }

    private var canCommit: Bool {
        hasMeaningfulDraft
    }

    private var textFieldForeground: Color {
        if trimmedDraft.isEmpty && !fieldFocused {
            return Color.primary.opacity(0.45)
        }
        return .primary
    }

    private var accessibilityLabelText: String {
        if let categoryAccessibilityName {
            String(
                localized: "quickentry.accessibility.add",
                defaultValue: "Neue Aufgabe in %@ hinzufügen"
            )
            .replacingOccurrences(of: "%@", with: categoryAccessibilityName)
        } else {
            String(localized: "quickentry.accessibility.addToday", defaultValue: "Neue Aufgabe für heute hinzufügen")
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
