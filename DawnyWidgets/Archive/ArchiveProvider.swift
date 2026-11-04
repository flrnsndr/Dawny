// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  ArchiveProvider.swift
//  DawnyWidgets
//

import WidgetKit

struct ArchiveEntry: TimelineEntry {
    enum State {
        case normal(ArchiveSnapshot)
        case needsAppLaunch
    }

    let date: Date
    let state: State
}

struct ArchiveProvider: TimelineProvider {
    func placeholder(in context: Context) -> ArchiveEntry {
        ArchiveEntry(date: Date(), state: .normal(.placeholder))
    }

    func getSnapshot(in context: Context, completion: @escaping (ArchiveEntry) -> Void) {
        _Concurrency.Task { @MainActor in
            completion(entry(now: Date()))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ArchiveEntry>) -> Void) {
        _Concurrency.Task { @MainActor in
            let now = Date()
            let next = ResetSchedule.nextThreshold(after: now, resetHour: WidgetDataSource.resetHour, calendar: .current)
            let entries = [entry(now: now), entry(now: next)]
            completion(Timeline(entries: entries, policy: .after(next)))
        }
    }

    @MainActor
    private func entry(now: Date) -> ArchiveEntry {
        guard WidgetDataSource.isAvailable else {
            return ArchiveEntry(date: now, state: .needsAppLaunch)
        }
        // Nach der Reset-Schwelle die „Als-ob"-archivierten Aufgaben zeigen.
        let asIf = WidgetDataSource.isResetPending(now: now)
        if let snapshot = try? WidgetDataSource.archiveSnapshot(now: now, asIf: asIf) {
            return ArchiveEntry(date: now, state: .normal(snapshot))
        }
        return ArchiveEntry(date: now, state: .needsAppLaunch)
    }
}
