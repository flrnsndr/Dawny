// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  BacklogProvider.swift
//  DawnyWidgets
//

import WidgetKit

struct BacklogEntry: TimelineEntry {
    enum State {
        case normal(BacklogSnapshot)
        case needsAppLaunch
    }

    let date: Date
    let state: State
    let showNavigation: Bool
    let configuredCategoryID: UUID?
}

struct BacklogProvider: AppIntentTimelineProvider {
    typealias Entry = BacklogEntry
    typealias Intent = BacklogConfigurationIntent

    func placeholder(in context: Context) -> BacklogEntry {
        BacklogEntry(date: Date(), state: .normal(.placeholder), showNavigation: false, configuredCategoryID: nil)
    }

    func snapshot(for configuration: BacklogConfigurationIntent, in context: Context) async -> BacklogEntry {
        await entry(for: configuration, now: Date())
    }

    func timeline(for configuration: BacklogConfigurationIntent, in context: Context) async -> Timeline<BacklogEntry> {
        let now = Date()
        let next = ResetSchedule.nextThreshold(after: now, resetHour: WidgetDataSource.resetHour, calendar: .current)
        // „now" (evtl. schon As-ob) + vorgerenderter As-ob-Flip zur nächsten Reset-Schwelle.
        let currentEntry = await entry(for: configuration, now: now)
        let nextEntry = await entry(for: configuration, now: next)
        return Timeline(entries: [currentEntry, nextEntry], policy: .after(next))
    }

    @MainActor
    private func entry(for configuration: BacklogConfigurationIntent, now: Date) -> BacklogEntry {
        guard WidgetDataSource.isAvailable else {
            return BacklogEntry(date: now, state: .needsAppLaunch, showNavigation: configuration.showNavigation, configuredCategoryID: configuration.category?.id)
        }
        // Nach der Reset-Schwelle den „Als-ob"-Stand zeigen.
        let asIf = WidgetDataSource.isResetPending(now: now)
        if let snapshot = try? WidgetDataSource.backlogSnapshot(now: now, asIf: asIf) {
            return BacklogEntry(
                date: now,
                state: .normal(snapshot),
                showNavigation: configuration.showNavigation,
                configuredCategoryID: configuration.category?.id
            )
        }
        return BacklogEntry(date: now, state: .needsAppLaunch, showNavigation: configuration.showNavigation, configuredCategoryID: configuration.category?.id)
    }
}
