// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

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
    let onToggle: () -> Void
    let onLongPress: () -> Void

    /// Mindestdauer für den Long-Press, der das Aktionsmenü öffnet.
    /// Gleich der Default-Dauer eines `.contextMenu`, damit es sich nativ anfühlt.
    fileprivate static let longPressDuration: Double = 0.45

    var body: some View {
        // Kein `Button`: sonst blockiert die Interaktion oft SwiftUI-`dropDestination` auf dem Header (Cross-Category-Drag).
        HStack(spacing: 8) {
            Image(systemName: category.displayIconName)
                .foregroundColor(.secondary)
                .frame(width: 18)

            HStack(spacing: 6) {
                Text(category.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                if category.isRecurring {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .accessibilityLabel(
                            String(
                                localized: "task.recurring.badge",
                                defaultValue: "Recurring"
                            )
                        )
                }
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
            }

            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
        .contentShape(Rectangle())
        .modifier(
            CategoryHeaderGesture(
                hasEditCapability: category.hasAnyEditCapability,
                onTap: onToggle,
                onLongPress: {
                    HapticFeedback.medium()
                    onLongPress()
                }
            )
        )
    }
}

/// Kombinierte Tap + Long-Press-Geste für den Section-Header.
///
/// Hintergrund: `.contextMenu` ist auf SwiftUI-`Section`-Headern unzuverlässig
/// (die Long-Press-Erkennung kollidiert mit `.onTapGesture` und dem System-
/// Hit-Testing der List). Wir nutzen stattdessen `.exclusively(before:)` mit
/// einem expliziten `LongPressGesture`. So sind beide Gesten klar voneinander
/// abgegrenzt: kurzer Tap → toggle, ≥ 0.45s halten → Aktionsmenü.
private struct CategoryHeaderGesture: ViewModifier {
    let hasEditCapability: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    func body(content: Content) -> some View {
        if hasEditCapability {
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
