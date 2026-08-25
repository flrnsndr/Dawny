// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  ReminderLinkRegistryTests.swift
//  DawnyTests
//
//  Unit Tests für das gerätelokale Verzeichnis erreichbarer Erinnerungen
//

import XCTest
@testable import Dawny

final class ReminderLinkRegistryTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!
    private var registry: ReminderLinkRegistry!

    override func setUp() {
        super.setUp()
        suiteName = "DawnyTests.ReminderLinkRegistry.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        registry = ReminderLinkRegistry(defaults: defaults)
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testUnknownIdentifierIsNotKnownLocally() {
        XCTAssertFalse(registry.isKnownLocally("id-vom-anderen-geraet"))
    }

    func testRememberedIdentifierIsKnownLocally() {
        registry.remember("reminder-1")

        XCTAssertTrue(registry.isKnownLocally("reminder-1"))
        XCTAssertFalse(registry.isKnownLocally("reminder-2"))
    }

    func testForgetRemovesTheIdentifier() {
        registry.remember("reminder-1")
        registry.forget("reminder-1")

        XCTAssertFalse(registry.isKnownLocally("reminder-1"))
    }

    /// Das Verzeichnis ist gerätelokaler Zustand und muss den Prozess überleben —
    /// sonst gilt nach jedem Neustart jede Verknüpfung als fremd.
    func testEntriesSurviveANewInstanceOverTheSameStore() {
        registry.remember("reminder-1")

        let reopened = ReminderLinkRegistry(defaults: defaults)

        XCTAssertTrue(reopened.isKnownLocally("reminder-1"))
    }

    /// Zwei Geräte teilen sich das Verzeichnis nicht.
    func testSeparateStoresDoNotShareEntries() {
        let otherSuiteName = "DawnyTests.ReminderLinkRegistry.\(UUID().uuidString)"
        defer { UserDefaults.standard.removePersistentDomain(forName: otherSuiteName) }
        let other = ReminderLinkRegistry(defaults: UserDefaults(suiteName: otherSuiteName)!)

        registry.remember("reminder-1")

        XCTAssertFalse(other.isKnownLocally("reminder-1"))
    }

    func testKeepOnlyDropsEntriesWithoutALinkedTask() {
        registry.remember("reminder-1")
        registry.remember("reminder-2")

        registry.keepOnly(["reminder-2"])

        XCTAssertFalse(registry.isKnownLocally("reminder-1"))
        XCTAssertTrue(registry.isKnownLocally("reminder-2"))
    }

    /// Ein leerer Store — etwa auf einem Gerät, dessen CloudKit-Import noch aussteht —
    /// darf das Verzeichnis leeren dürfen: Zu wenig zu wissen macht nur vorsichtiger.
    func testKeepOnlyWithAnEmptySetClearsEverything() {
        registry.remember("reminder-1")

        registry.keepOnly([])

        XCTAssertFalse(registry.isKnownLocally("reminder-1"))
    }
}
