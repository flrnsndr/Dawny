//
//  CategoryHeaderView.swift
//  Dawny
//
//  Header-View für kollabierbare Kategorie-Sections
//

import SwiftUI

struct CategoryHeaderView: View {
    let category: Category
    let taskCount: Int
    let isExpanded: Bool
    let isEditingName: Bool
    /// True, solange BacklogView den Symbol-Picker als Sheet präsentiert.
    /// Wird genutzt, um beim temporären Fokusverlust des TextFields nicht
    /// fälschlich den Inline-Rename zu committen oder abzubrechen.
    let isIconPickerOpen: Bool
    let onToggle: () -> Void
    let onLongPress: () -> Void
    let onCommitRename: (String) -> Void
    let onCancelRename: () -> Void
    /// Wird aufgerufen, wenn der User im Edit-Modus auf das Icon tippt.
    let onIconTap: () -> Void

    /// Mindestdauer für den Long-Press, der das Aktionsmenü öffnet.
    /// Gleich der Default-Dauer eines `.contextMenu`, damit es sich nativ anfühlt.
    fileprivate static let longPressDuration: Double = 0.45

    var body: some View {
        // Kein `Button`: sonst blockiert die Interaktion oft SwiftUI-`dropDestination` auf dem Header (Cross-Category-Drag).
        HStack(spacing: 8) {
            iconView

            if isEditingName {
                InlineCategoryNameField(
                    initialName: category.displayName,
                    maxLength: CategoryService.maxNameLength,
                    isIconPickerOpen: isIconPickerOpen,
                    onCommit: onCommitRename,
                    onCancel: onCancelRename
                )
            } else {
                Text(category.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Spacer()

            if taskCount > 0 {
                Text(taskCount, format: .number)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
                    .opacity(isEditingName ? 0.5 : 1.0)
            }

            if !isEditingName {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
        }
        .contentShape(Rectangle())
        .modifier(
            CategoryHeaderGesture(
                isEditingName: isEditingName,
                hasEditCapability: category.hasAnyEditCapability,
                onTap: onToggle,
                onLongPress: {
                    HapticFeedback.medium()
                    onLongPress()
                }
            )
        )
    }

    /// Im Anzeige-Modus dezent (sekundärfarben). Im Edit-Modus zur tappbaren
    /// Schaltfläche aufgewertet (Akzentfarbe + Hintergrund), damit klar wird:
    /// hier kann der User das Symbol antippen, um den Picker zu öffnen.
    @ViewBuilder
    private var iconView: some View {
        if isEditingName && category.canChangeIcon {
            Button {
                HapticFeedback.light()
                onIconTap()
            } label: {
                Image(systemName: category.displayIconName)
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.accentColor.opacity(0.15))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                String(
                    localized: "category.action.changeIcon",
                    defaultValue: "Change symbol"
                )
            )
        } else {
            Image(systemName: category.displayIconName)
                .foregroundColor(.secondary)
                .frame(width: 18)
                .opacity(isEditingName ? 0.5 : 1.0)
        }
    }
}

// MARK: - Inline Name Field

/// Eigenständige Sub-View für das Inline-Rename-TextField.
///
/// Wichtiger Punkt: `@State private var draft` wird im `init` aus `initialName`
/// initialisiert. Dadurch zeigt das Feld vom ersten Frame an den aktuellen
/// Kategorienamen (statt eines grauen Placeholder-Texts oder eines kurzen
/// Flackerns mit leerem Inhalt). Die Sub-View wird beim Eintritt in den
/// Edit-Modus frisch erstellt, daher greift der Initialwert zuverlässig.
private struct InlineCategoryNameField: View {
    let initialName: String
    let maxLength: Int
    let isIconPickerOpen: Bool
    let onCommit: (String) -> Void
    let onCancel: () -> Void

    @State private var draft: String
    @FocusState private var isFocused: Bool

    init(
        initialName: String,
        maxLength: Int,
        isIconPickerOpen: Bool,
        onCommit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialName = initialName
        self.maxLength = maxLength
        self.isIconPickerOpen = isIconPickerOpen
        self.onCommit = onCommit
        self.onCancel = onCancel
        _draft = State(initialValue: initialName)
    }

    private var trimmed: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        !trimmed.isEmpty && trimmed.count <= maxLength
    }

    var body: some View {
        HStack(spacing: 8) {
            // Bewusst leerer Placeholder: der Initialwert von `draft` ist
            // immer der aktuelle Kategoriename, sodass kein Placeholder
            // sichtbar wird. Falls der User den Text komplett löscht, bleibt
            // das Feld leer (Done-Button wird dann disabled).
            TextField("", text: $draft)
                .font(.headline)
                .foregroundColor(.primary)
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
            // Async setzen, damit das TextField bereits gemountet ist und der
            // Fokus die Tastatur zuverlässig öffnet.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFocused = true
            }
        }
        .onChange(of: isFocused) { wasFocused, isNowFocused in
            // Wenn der User den Fokus verliert, weil der Symbol-Picker als
            // Sheet kommt, NICHT committen. Der Edit-Modus bleibt aktiv und
            // wir refokussieren das Feld, sobald der Picker wieder geschlossen
            // ist.
            if isIconPickerOpen { return }
            // Wenn der User ausserhalb tippt: bei gültigem Namen committen,
            // sonst Edit abbrechen ohne Speichern.
            guard wasFocused, !isNowFocused else { return }
            if isValid {
                submit()
            } else {
                onCancel()
            }
        }
        .onChange(of: isIconPickerOpen) { wasOpen, isOpen in
            // Picker hat sich geschlossen → Tastatur wieder einblenden, damit
            // der User direkt am Namen weiterarbeiten kann.
            if wasOpen && !isOpen {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isFocused = true
                }
            }
        }
    }

    private func submit() {
        guard isValid else {
            HapticFeedback.error()
            return
        }
        // Wenn sich nichts geändert hat: still beenden, kein Save-Roundtrip.
        if trimmed == initialName {
            onCancel()
            return
        }
        onCommit(trimmed)
    }
}

/// Kombinierte Tap + Long-Press-Geste für den Section-Header.
///
/// Hintergrund: `.contextMenu` ist auf SwiftUI-`Section`-Headern unzuverlässig
/// (die Long-Press-Erkennung kollidiert mit `.onTapGesture` und dem System-
/// Hit-Testing der List). Wir nutzen stattdessen `.exclusively(before:)` mit
/// einem expliziten `LongPressGesture`. So sind beide Gesten klar voneinander
/// abgegrenzt: kurzer Tap → toggle, ≥ 0.45s halten → Aktionsmenü.
///
/// Während des Inline-Renames wird die Geste komplett deaktiviert, damit das
/// `TextField` Taps exklusiv erhält.
private struct CategoryHeaderGesture: ViewModifier {
    let isEditingName: Bool
    let hasEditCapability: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    func body(content: Content) -> some View {
        if isEditingName {
            content
        } else if hasEditCapability {
            content.gesture(
                LongPressGesture(minimumDuration: CategoryHeaderView.longPressDuration)
                    .onEnded { _ in onLongPress() }
                    .exclusively(
                        before: TapGesture().onEnded { onTap() }
                    )
            )
        } else {
            // Gesperrte Kategorie (Unkategorisiert): nur Tap zum Auf-/Zuklappen,
            // kein Long-Press.
            content.onTapGesture(perform: onTap)
        }
    }
}
