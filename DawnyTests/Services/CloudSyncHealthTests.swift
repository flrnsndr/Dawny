// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  CloudSyncHealthTests.swift
//  DawnyTests
//
//  Deckt die Erkennung von vollem iCloud-Speicher in CloudKit-Sync-Events ab.
//

import XCTest
import CloudKit
import CoreData
@testable import Dawny

@MainActor
final class CloudSyncHealthTests: XCTestCase {

    private let quotaError = CKError(.quotaExceeded)

    func testDetectsDirectQuotaError() {
        XCTAssertTrue(CloudSyncHealth.indicatesQuotaExceeded(quotaError))
    }

    func testDetectsQuotaErrorInsidePartialFailure() {
        let partial = CKError(.partialFailure, userInfo: [
            CKPartialErrorsByItemIDKey: [CKRecord.ID(recordName: "a"): quotaError]
        ])
        XCTAssertTrue(CloudSyncHealth.indicatesQuotaExceeded(partial))
    }

    func testDetectsQuotaErrorWrappedAsUnderlyingError() {
        let wrapped = NSError(domain: NSCocoaErrorDomain, code: 134400, userInfo: [NSUnderlyingErrorKey: quotaError])
        XCTAssertTrue(CloudSyncHealth.indicatesQuotaExceeded(wrapped))
    }

    func testIgnoresOtherErrors() {
        XCTAssertFalse(CloudSyncHealth.indicatesQuotaExceeded(CKError(.zoneNotFound)))
        XCTAssertFalse(CloudSyncHealth.indicatesQuotaExceeded(CKError(.networkUnavailable)))
        let partial = CKError(.partialFailure, userInfo: [
            CKPartialErrorsByItemIDKey: [CKRecord.ID(recordName: "a"): CKError(.serverRecordChanged)]
        ])
        XCTAssertFalse(CloudSyncHealth.indicatesQuotaExceeded(partial))
    }

    func testSuccessfulExportClearsQuotaState() {
        let health = CloudSyncHealth()
        health.record(type: .export, succeeded: false, error: quotaError)
        XCTAssertTrue(health.isQuotaExceeded)

        // Ein erfolgreicher Import heißt nicht, dass wieder hochgeladen werden kann.
        health.record(type: .import, succeeded: true, error: nil)
        XCTAssertTrue(health.isQuotaExceeded)

        health.record(type: .export, succeeded: true, error: nil)
        XCTAssertFalse(health.isQuotaExceeded)
    }

    func testOtherFailuresKeepQuotaState() {
        let health = CloudSyncHealth()
        health.record(type: .export, succeeded: false, error: quotaError)
        health.record(type: .export, succeeded: false, error: CKError(.networkUnavailable))
        XCTAssertTrue(health.isQuotaExceeded)
    }
}
