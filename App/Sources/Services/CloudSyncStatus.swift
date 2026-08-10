// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  CloudSyncStatus.swift
//  Dawny
//
//  Informativer iCloud-Account-Status für die Settings-Anzeige.
//

import CloudKit
import Foundation

/// Fragt ab, ob der iCloud-Account des Geräts für den Sync bereitsteht.
///
/// Rein informativ: die App läuft immer lokal weiter, egal was hier herauskommt.
/// Läuft ausschließlich im App-Prozess (die Widget-Extension synct nicht).
enum CloudSyncStatus {
    enum Availability {
        case available
        case unavailable
    }

    /// Jeder Fehler (fehlendes Entitlement, kein Netz, abgemeldet) wird zu
    /// `.unavailable` — der Aufrufer soll daraus nie eine Blockade ableiten.
    static func accountAvailability() async -> Availability {
        do {
            let status = try await CKContainer(identifier: CloudKitConfig.containerID).accountStatus()
            return status == .available ? .available : .unavailable
        } catch {
            return .unavailable
        }
    }
}
