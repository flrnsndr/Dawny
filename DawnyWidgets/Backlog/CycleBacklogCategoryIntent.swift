// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  CycleBacklogCategoryIntent.swift
//  DawnyWidgets
//

import AppIntents
import WidgetKit

enum CycleDirection: String, AppEnum {
    case forward
    case backward

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(
        name: "widget.backlog.cycle.direction"
    )
    static var caseDisplayRepresentations: [CycleDirection: DisplayRepresentation] = [
        .forward: DisplayRepresentation(title: "widget.backlog.cycle.forward"),
        .backward: DisplayRepresentation(title: "widget.backlog.cycle.backward")
    ]
}

/// Blättert die im Backlog-Medium gezeigte Kategorie um. Schreibt den Index in die
/// geteilte Suite und lädt nur das Backlog-Widget neu. Reines Widget-Plumbing.
struct CycleBacklogCategoryIntent: AppIntent {
    static var title: LocalizedStringResource = "widget.backlog.cycle.title"
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false

    @Parameter(title: "widget.backlog.cycle.direction")
    var direction: CycleDirection

    init() {}
    init(direction: CycleDirection) {
        self.direction = direction
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let now = Date()
        let sectionCount = (try? WidgetDataSource.backlogSnapshot(now: now, asIf: false).sections.count) ?? 0
        guard sectionCount > 0 else { return .result() }

        let current = AppGroup.defaults.integer(forKey: WidgetDefaultsKey.backlogCategoryIndex)
        let delta = (direction == .forward) ? 1 : -1
        // Positiver Modulo für Wrap-around in beide Richtungen.
        let next = ((current + delta) % sectionCount + sectionCount) % sectionCount

        AppGroup.defaults.set(next, forKey: WidgetDefaultsKey.backlogCategoryIndex)
        WidgetCenter.shared.reloadTimelines(ofKind: BacklogWidget.kind)
        return .result()
    }
}
