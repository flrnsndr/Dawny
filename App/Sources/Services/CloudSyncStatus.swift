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
import CoreData
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

/// Merkt sich, ob der iCloud-Speicher des Nutzers voll ist und der Upload deshalb stockt.
///
/// Dawny synct in die private CloudKit-Datenbank, deren Speicher vom iCloud-Kontingent
/// des Nutzers abgeht. Ist es aufgebraucht, scheitert jeder Export mit `quotaExceeded`,
/// ohne dass die App davon etwas mitbekommt: lokal läuft alles weiter, nur die anderen
/// Geräte bleiben stehen. Der Container versucht es später selbst erneut, deshalb
/// hebt der nächste erfolgreiche Export den Zustand wieder auf.
///
/// Nur im Speicher gehalten: nach einem Neustart meldet sich der Zustand beim nächsten
/// Export-Versuch von selbst zurück.
@MainActor
@Observable
final class CloudSyncHealth {
    static let shared = CloudSyncHealth()

    private(set) var isQuotaExceeded = false

    @ObservationIgnored private var observer: NSObjectProtocol?

    /// Vor dem Bau des ModelContainers aufrufen, damit schon die Events des ersten
    /// Exports nach dem Start ankommen. SwiftData meldet sie über den
    /// `NSPersistentCloudKitContainer`, den es intern verwendet.
    func startObserving() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event,
                  // Jedes Event kommt zweimal: beim Start ohne, beim Ende mit endDate.
                  event.endDate != nil else { return }
            let type = event.type
            let succeeded = event.succeeded
            let error = event.error
            MainActor.assumeIsolated {
                self?.record(type: type, succeeded: succeeded, error: error)
            }
        }
    }

    func record(type: NSPersistentCloudKitContainer.EventType, succeeded: Bool, error: Error?) {
        if let error, Self.indicatesQuotaExceeded(error) {
            isQuotaExceeded = true
        } else if type == .export, succeeded {
            isQuotaExceeded = false
        }
    }

    /// CloudKit liefert `quotaExceeded` direkt, als Teilfehler eines `partialFailure`
    /// oder von Core Data als `NSUnderlyingErrorKey` verpackt.
    nonisolated static func indicatesQuotaExceeded(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == CKError.errorDomain {
            if nsError.code == CKError.Code.quotaExceeded.rawValue {
                return true
            }
            if nsError.code == CKError.Code.partialFailure.rawValue,
               let partialErrors = nsError.userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: Error],
               partialErrors.values.contains(where: { indicatesQuotaExceeded($0) }) {
                return true
            }
        }
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            return indicatesQuotaExceeded(underlying)
        }
        return false
    }
}
