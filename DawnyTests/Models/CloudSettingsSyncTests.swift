// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  CloudSettingsSyncTests.swift
//  DawnyTests
//
//  Deckt den iCloud-Abgleich der verhaltensrelevanten Einstellungen ab.
//  Diese drei Werte müssen auf allen Geräten gleich sein, sonst können zwei
//  Geräte beim nächtlichen Reset widersprüchliche Ergebnisse schreiben
//  (siehe ResetConvergenceTests).
//

import XCTest
@testable import Dawny

@MainActor
final class CloudSettingsSyncTests: XCTestCase {

    private var store: MockUbiquitousKeyValueStore!
    private var settings: AppSettings!

    override func setUp() async throws {
        store = MockUbiquitousKeyValueStore()
        settings = AppSettings(cloudStore: store)
        settings.iCloudSyncEnabled = true
    }

    override func tearDown() async throws {
        // `AppSettings` schreibt immer in die geteilte Suite — Flag zurücksetzen,
        // damit andere Tests nicht plötzlich mit aktiviertem Sync laufen.
        settings.iCloudSyncEnabled = false
        AppGroup.defaults.removeObject(forKey: AppSettings.Keys.iCloudSyncEnabled)
    }

    // MARK: - Push

    func testLocalChangePushesToCloud() {
        settings.resetHour = 5
        settings.makeItCountThreshold = 4
        settings.defaultCategoryType = .someday

        XCTAssertEqual(store.object(forKey: AppSettings.CloudKeys.resetHour) as? Int, 5)
        XCTAssertEqual(store.object(forKey: AppSettings.CloudKeys.makeItCountThreshold) as? Int, 4)
        XCTAssertEqual(
            store.object(forKey: AppSettings.CloudKeys.defaultCategoryType) as? String,
            TaskCategory.someday.rawValue
        )
    }

    func testNothingIsPushedWhileSyncIsDisabled() {
        settings.iCloudSyncEnabled = false
        settings.resetHour = 7

        XCTAssertNil(store.object(forKey: AppSettings.CloudKeys.resetHour))
    }

    // MARK: - Adopt

    func testExistingCloudValuesWinOnActivation() {
        let remote = MockUbiquitousKeyValueStore(initialValues: [
            AppSettings.CloudKeys.resetHour: 6,
            AppSettings.CloudKeys.makeItCountThreshold: 5,
            AppSettings.CloudKeys.defaultCategoryType: TaskCategory.nextFewWeeks.rawValue
        ])

        // Abweichende lokale Werte setzen, solange der Sync noch aus ist —
        // sonst würden sie die Cloud-Werte überschreiben, bevor der Abgleich läuft.
        let secondDevice = AppSettings(cloudStore: remote)
        secondDevice.iCloudSyncEnabled = false
        secondDevice.resetHour = 3
        secondDevice.makeItCountThreshold = 1
        secondDevice.defaultCategoryType = .quick

        secondDevice.iCloudSyncEnabled = true
        secondDevice.activateCloudSyncIfEnabled()

        XCTAssertEqual(secondDevice.resetHour, 6, "Der Cloud-Wert gewinnt beim Einschalten")
        XCTAssertEqual(secondDevice.makeItCountThreshold, 5)
        XCTAssertEqual(secondDevice.defaultCategoryType, .nextFewWeeks)

        secondDevice.iCloudSyncEnabled = false
    }

    func testLocalValuesArePushedWhenCloudIsEmpty() {
        settings.resetHour = 4
        settings.makeItCountThreshold = 2
        store.set(nil, forKey: AppSettings.CloudKeys.resetHour)
        store.set(nil, forKey: AppSettings.CloudKeys.makeItCountThreshold)
        store.set(nil, forKey: AppSettings.CloudKeys.defaultCategoryType)

        settings.activateCloudSyncIfEnabled()

        XCTAssertEqual(store.object(forKey: AppSettings.CloudKeys.resetHour) as? Int, 4)
        XCTAssertEqual(store.object(forKey: AppSettings.CloudKeys.makeItCountThreshold) as? Int, 2)
        XCTAssertNotNil(store.object(forKey: AppSettings.CloudKeys.defaultCategoryType))
    }

    func testAdoptedValuesAreAlsoPersistedLocally() {
        let remote = MockUbiquitousKeyValueStore(initialValues: [
            AppSettings.CloudKeys.resetHour: 9
        ])
        let device = AppSettings(cloudStore: remote)
        device.iCloudSyncEnabled = true

        device.activateCloudSyncIfEnabled()

        XCTAssertEqual(device.resetHour, 9)
        XCTAssertEqual(AppGroup.defaults.object(forKey: AppSettings.Keys.resetHour) as? Int, 9)

        device.iCloudSyncEnabled = false
    }

    func testActivationIsInertWhileSyncIsDisabled() {
        let remote = MockUbiquitousKeyValueStore(initialValues: [
            AppSettings.CloudKeys.resetHour: 11
        ])
        let device = AppSettings(cloudStore: remote)
        device.iCloudSyncEnabled = false
        let hourBefore = device.resetHour

        device.activateCloudSyncIfEnabled()

        XCTAssertEqual(device.resetHour, hourBefore)
    }
}
