// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  WidgetPreviews.swift
//  DawnyWidgets
//
//  Xcode-Canvas-Previews für alle Widgets (Beispieldaten, kein Home-Screen nötig).
//

import SwiftUI
import WidgetKit

// MARK: - Beispiel-Snapshots mit mehreren Kategorien (für Navigation/Large)

private let sampleBacklog = BacklogSnapshot(
    sections: [
        WidgetCategorySection(
            id: UUID(), name: "Quick", iconName: "bolt.fill", openCount: 4,
            tasks: [
                WidgetTask(id: UUID(), title: "Rechnung zahlen", categoryIconName: "bolt.fill"),
                WidgetTask(id: UUID(), title: "Termin buchen", categoryIconName: "bolt.fill"),
                WidgetTask(id: UUID(), title: "Rückruf", categoryIconName: "bolt.fill")
            ]
        ),
        WidgetCategorySection(
            id: UUID(), name: "Nächste Tage", iconName: "calendar", openCount: 2,
            tasks: [
                WidgetTask(id: UUID(), title: "Präsentation", categoryIconName: "calendar"),
                WidgetTask(id: UUID(), title: "Einkauf planen", categoryIconName: "calendar")
            ]
        ),
        WidgetCategorySection(
            id: UUID(), name: "Irgendwann", iconName: "infinity", openCount: 1,
            tasks: [WidgetTask(id: UUID(), title: "Buch lesen", categoryIconName: "infinity")]
        )
    ],
    selectedSectionIndex: 0
)

// MARK: - Heute

#Preview("Heute – Small", as: .systemSmall) {
    TodayWidget()
} timeline: {
    TodayEntry(date: .now, state: .normal(.placeholder), resetHint: .perTaskSymbol)
}

#Preview("Heute – Medium (Normal / Reset)", as: .systemMedium) {
    TodayWidget()
} timeline: {
    TodayEntry(date: .now, state: .normal(.placeholder), resetHint: .perTaskSymbol)
    TodayEntry(date: .now, state: .resetPending, resetHint: .perTaskSymbol)
}

#Preview("Heute – Large", as: .systemLarge) {
    TodayWidget()
} timeline: {
    TodayEntry(date: .now, state: .normal(.placeholder), resetHint: .perTaskSymbol)
}

#Preview("Heute – Öffne Dawny", as: .systemSmall) {
    TodayWidget()
} timeline: {
    TodayEntry(date: .now, state: .needsAppLaunch, resetHint: .perTaskSymbol)
}

#Preview("Heute – Lock (Rechteckig)", as: .accessoryRectangular) {
    TodayWidget()
} timeline: {
    TodayEntry(date: .now, state: .normal(.placeholder), resetHint: .perTaskSymbol)
}

#Preview("Heute – Lock (Rund)", as: .accessoryCircular) {
    TodayWidget()
} timeline: {
    TodayEntry(date: .now, state: .normal(.placeholder), resetHint: .perTaskSymbol)
}

// MARK: - Backlog

#Preview("Backlog – Small", as: .systemSmall) {
    BacklogWidget()
} timeline: {
    BacklogEntry(date: .now, state: .normal(sampleBacklog), showNavigation: false, configuredCategoryID: nil)
}

#Preview("Backlog – Medium", as: .systemMedium) {
    BacklogWidget()
} timeline: {
    BacklogEntry(date: .now, state: .normal(sampleBacklog), showNavigation: false, configuredCategoryID: nil)
}

#Preview("Backlog – Medium (Navigation)", as: .systemMedium) {
    BacklogWidget()
} timeline: {
    BacklogEntry(date: .now, state: .normal(sampleBacklog), showNavigation: true, configuredCategoryID: nil)
}

#Preview("Backlog – Large", as: .systemLarge) {
    BacklogWidget()
} timeline: {
    BacklogEntry(date: .now, state: .normal(sampleBacklog), showNavigation: false, configuredCategoryID: nil)
}

// MARK: - Archiv

#Preview("Archiv – Small", as: .systemSmall) {
    ArchiveWidget()
} timeline: {
    ArchiveEntry(date: .now, state: .normal(.placeholder))
}

#Preview("Archiv – Medium", as: .systemMedium) {
    ArchiveWidget()
} timeline: {
    ArchiveEntry(date: .now, state: .normal(.placeholder))
}
