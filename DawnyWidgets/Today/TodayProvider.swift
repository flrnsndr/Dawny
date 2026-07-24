// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  TodayProvider.swift
//  DawnyWidgets
//

import WidgetKit

struct TodayEntry: TimelineEntry {
    enum State {
        case normal(TodaySnapshot)
        /// Reset-Schwelle überschritten, App hat noch nicht aufgeräumt.
        case resetPending
        /// Store noch nicht migriert → App einmal öffnen.
        case needsAppLaunch
    }

    let date: Date
    let state: State
    let resetHint: ResetHintMode
}

struct TodayProvider: AppIntentTimelineProvider {
    typealias Entry = TodayEntry
    typealias Intent = TodayConfigurationIntent

    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), state: .normal(.placeholder), resetHint: .perTaskSymbol)
    }

    func snapshot(for configuration: TodayConfigurationIntent, in context: Context) async -> TodayEntry {
        await entry(for: configuration, now: Date())
    }

    func timeline(for configuration: TodayConfigurationIntent, in context: Context) async -> Timeline<TodayEntry> {
        let now = Date()
        let current = await entry(for: configuration, now: now)
        let next = ResetSchedule.nextThreshold(after: now, resetHour: WidgetDataSource.resetHour, calendar: .current)

        // Bei bereits fälligem Reset nur den Pending-Eintrag zeigen.
        if case .resetPending = current.state {
            return Timeline(entries: [current], policy: .after(next))
        }
        // Sonst: jetzt + vorgerenderter Flip in den Pending-Zustand zur nächsten Schwelle.
        let pending = TodayEntry(date: next, state: .resetPending, resetHint: configuration.resetHint)
        return Timeline(entries: [current, pending], policy: .after(next))
    }

    @MainActor
    private func entry(for configuration: TodayConfigurationIntent, now: Date) -> TodayEntry {
        guard WidgetDataSource.isAvailable else {
            return TodayEntry(date: now, state: .needsAppLaunch, resetHint: configuration.resetHint)
        }
        if WidgetDataSource.isResetPending(now: now) {
            return TodayEntry(date: now, state: .resetPending, resetHint: configuration.resetHint)
        }
        if let snapshot = try? WidgetDataSource.todaySnapshot(now: now) {
            return TodayEntry(date: now, state: .normal(snapshot), resetHint: configuration.resetHint)
        }
        return TodayEntry(date: now, state: .needsAppLaunch, resetHint: configuration.resetHint)
    }
}
