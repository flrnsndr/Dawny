// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  MockUbiquitousKeyValueStore.swift
//  DawnyTests
//
//  In-Memory-Ersatz für NSUbiquitousKeyValueStore.
//

import Foundation
@testable import Dawny

/// Speichert Werte im Arbeitsspeicher, damit die Settings-Synchronisation
/// ohne echten iCloud-Account getestet werden kann.
final class MockUbiquitousKeyValueStore: UbiquitousKeyValueStoring {
    private(set) var storage: [String: Any] = [:]
    private(set) var synchronizeCallCount = 0

    init(initialValues: [String: Any] = [:]) {
        self.storage = initialValues
    }

    func object(forKey key: String) -> Any? {
        storage[key]
    }

    func set(_ value: Any?, forKey key: String) {
        if let value {
            storage[key] = value
        } else {
            storage.removeValue(forKey: key)
        }
    }

    @discardableResult
    func synchronize() -> Bool {
        synchronizeCallCount += 1
        return true
    }
}
