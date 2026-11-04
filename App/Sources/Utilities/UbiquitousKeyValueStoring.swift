// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  UbiquitousKeyValueStoring.swift
//  Dawny
//
//  Testbare Abstraktion über NSUbiquitousKeyValueStore.
//

import Foundation

/// Schmale Abstraktion über `NSUbiquitousKeyValueStore`, damit die
/// Settings-Synchronisation ohne echten iCloud-Account testbar bleibt.
protocol UbiquitousKeyValueStoring: AnyObject {
    func object(forKey key: String) -> Any?
    func set(_ value: Any?, forKey key: String)
    @discardableResult
    func synchronize() -> Bool
}

extension NSUbiquitousKeyValueStore: UbiquitousKeyValueStoring {}
