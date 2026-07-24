// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  ResetOutcomePlannerTests.swift
//  DawnyTests
//
//  Unit Tests für die reine Reset-Entscheidungslogik.
//

import XCTest
@testable import Dawny

final class ResetOutcomePlannerTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func input(
        status: TaskStatus,
        isCompleted: Bool = false,
        isRecurring: Bool = false,
        autoArchiveDays: Int? = nil,
        resetCount: Int = 0,
        enteredBacklogAt: Date? = nil
    ) -> ResetPlanInput {
        ResetPlanInput(
            status: status,
            isCompleted: isCompleted,
            isRecurring: isRecurring,
            categoryAutoArchiveDays: autoArchiveDays,
            resetCount: resetCount,
            enteredBacklogAt: enteredBacklogAt
        )
    }

    private func outcome(_ input: ResetPlanInput, threshold: Int = 1) -> ResetOutcome {
        ResetOutcomePlanner.outcome(
            for: input,
            referenceDate: now,
            makeItCountThreshold: threshold,
            calendar: calendar
        )
    }

    // MARK: - Kerninvariante: wiederkehrende Tasks werden nie archiviert

    func testRecurringDailyFocusNeverArchivesEvenWithHighResetCount() {
        let result = outcome(
            input(status: .dailyFocus, isRecurring: true, resetCount: 99),
            threshold: 1
        )
        XCTAssertEqual(result, .returnToBacklog(incrementsResetCount: false))
    }

    func testRecurringBacklogWithAutoArchiveDaysNeverArchives() {
        // Selbst wenn (theoretisch) autoArchiveDays gesetzt wäre: recurring → keine Auto-Tidy.
        let entered = calendar.date(byAdding: .day, value: -100, to: now)!
        let result = outcome(
            input(status: .inBacklog, isRecurring: true, autoArchiveDays: 7, enteredBacklogAt: entered)
        )
        XCTAssertEqual(result, .none)
    }

    // MARK: - Make It Count (Heute-Pfad)

    func testDailyFocusArchivesAtThresholdBoundary() {
        // resetCount 0, Schwelle 1 → 0 + 1 >= 1 → archivieren.
        let result = outcome(input(status: .dailyFocus, resetCount: 0), threshold: 1)
        XCTAssertEqual(result, .archive(.makeItCount))
    }

    func testDailyFocusReturnsToBacklogBelowThreshold() {
        // resetCount 0, Schwelle 3 → 0 + 1 = 1 < 3 → zurück ins Backlog, Zähler hoch.
        let result = outcome(input(status: .dailyFocus, resetCount: 0), threshold: 3)
        XCTAssertEqual(result, .returnToBacklog(incrementsResetCount: true))
    }

    func testDailyFocusArchivesWhenIncrementReachesThreshold() {
        // resetCount 2, Schwelle 3 → 2 + 1 = 3 >= 3 → archivieren.
        let result = outcome(input(status: .dailyFocus, resetCount: 2), threshold: 3)
        XCTAssertEqual(result, .archive(.makeItCount))
    }

    func testCompletedDailyFocusIsUnchanged() {
        let result = outcome(input(status: .dailyFocus, isCompleted: true))
        XCTAssertEqual(result, .none)
    }

    // MARK: - Auto-Tidy (Backlog-Pfad)

    func testAutoTidyArchivesAtExactCutoff() {
        // enteredBacklogAt + days == referenceDate → cutoff <= referenceDate → archivieren.
        let entered = calendar.date(byAdding: .day, value: -7, to: now)!
        let result = outcome(
            input(status: .inBacklog, autoArchiveDays: 7, enteredBacklogAt: entered)
        )
        XCTAssertEqual(result, .archive(.autoTidy))
    }

    func testAutoTidyDoesNotArchiveBeforeCutoff() {
        let entered = calendar.date(byAdding: .day, value: -3, to: now)!
        let result = outcome(
            input(status: .inBacklog, autoArchiveDays: 7, enteredBacklogAt: entered)
        )
        XCTAssertEqual(result, .none)
    }

    func testBacklogWithoutAutoArchiveDaysIsUnchanged() {
        let entered = calendar.date(byAdding: .day, value: -100, to: now)!
        let result = outcome(
            input(status: .inBacklog, autoArchiveDays: nil, enteredBacklogAt: entered)
        )
        XCTAssertEqual(result, .none)
    }

    func testBacklogWithoutEnteredDateIsUnchanged() {
        let result = outcome(
            input(status: .inBacklog, autoArchiveDays: 7, enteredBacklogAt: nil)
        )
        XCTAssertEqual(result, .none)
    }

    // MARK: - Andere Status

    func testScheduledCompletedArchivedAreUnchanged() {
        for status in [TaskStatus.scheduled, .completed, .archived] {
            XCTAssertEqual(outcome(input(status: status)), .none, "Status \(status) sollte unverändert bleiben")
        }
    }

    // MARK: - ResetSchedule

    func testLastThresholdIsTodayWhenAfterResetHour() {
        // 2023-11-14 22:13:20 UTC, resetHour 3 → letzter Threshold heute 03:00.
        let last = ResetSchedule.lastThreshold(before: now, resetHour: 3, calendar: utcCalendar)
        let comps = utcCalendar.dateComponents([.year, .month, .day, .hour], from: last)
        XCTAssertEqual(comps.hour, 3)
        XCTAssertEqual(comps.day, utcCalendar.component(.day, from: now))
    }

    func testLastThresholdIsYesterdayWhenBeforeResetHour() {
        // 01:00 UTC am gleichen Tag → letzter Threshold gestern 03:00.
        let earlyMorning = utcCalendar.date(bySettingHour: 1, minute: 0, second: 0, of: now)!
        let last = ResetSchedule.lastThreshold(before: earlyMorning, resetHour: 3, calendar: utcCalendar)
        let expectedDay = utcCalendar.component(.day, from: earlyMorning) - 1
        XCTAssertEqual(utcCalendar.component(.hour, from: last), 3)
        XCTAssertEqual(utcCalendar.component(.day, from: last), expectedDay)
    }

    func testNextThresholdIsOneDayAfterLast() {
        let last = ResetSchedule.lastThreshold(before: now, resetHour: 3, calendar: utcCalendar)
        let next = ResetSchedule.nextThreshold(after: now, resetHour: 3, calendar: utcCalendar)
        XCTAssertEqual(next.timeIntervalSince(last), 24 * 60 * 60, accuracy: 1)
    }

    private var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }
}
