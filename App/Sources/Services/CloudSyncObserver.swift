// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  CloudSyncObserver.swift
//  Dawny
//
//  Reagiert auf eingehende CloudKit-Änderungen im App-Prozess.
//

import CoreData
import Foundation
import SwiftData

/// Beobachtet Remote-Änderungen des CloudKit-gekoppelten Stores und bringt
/// UI, Widgets und Duplikat-Reparatur auf Stand.
///
/// Läuft ausschließlich im App-Prozess und nur bei aktiviertem iCloud-Sync —
/// die Widget-Extension liest den Store weiterhin lokal.
@MainActor
final class CloudSyncObserver {
    private let modelContext: ModelContext
    private var observerTask: _Concurrency.Task<Void, Never>?
    private var pendingHandlingTask: _Concurrency.Task<Void, Never>?
    private let debounceInterval: Duration = .seconds(1)

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    deinit {
        observerTask?.cancel()
        pendingHandlingTask?.cancel()
    }

    /// Startet die Beobachtung. Ohne aktivierten Sync passiert nichts.
    func startObserving() {
        guard AppSettings.shared.iCloudSyncEnabled, observerTask == nil else { return }

        print("☁️ CloudSyncObserver: Beobachtung gestartet")
        observerTask = _Concurrency.Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(
                named: .NSPersistentStoreRemoteChange
            )
            for await _ in notifications {
                guard let self else { return }
                print("☁️ CloudSyncObserver: Remote-Change eingetroffen")
                self.scheduleHandling()
            }
        }
    }

    func stopObserving() {
        observerTask?.cancel()
        observerTask = nil
        pendingHandlingTask?.cancel()
        pendingHandlingTask = nil
    }

    /// CloudKit liefert Änderungen in Schüben. Der erste Impuls plant einen Lauf
    /// in `debounceInterval`, alle weiteren des Schubs fallen darauf zusammen —
    /// sonst würde jede einzelne Benachrichtigung ein UI-Reload auslösen.
    private func scheduleHandling() {
        guard pendingHandlingTask == nil else { return }

        pendingHandlingTask = _Concurrency.Task { [weak self] in
            guard let self else { return }
            try? await _Concurrency.Task.sleep(for: self.debounceInterval)
            self.pendingHandlingTask = nil
            await self.handleRemoteChanges()
        }
    }

    /// Räumt Duplikate weg und stößt ein UI-/Widget-Update an.
    /// Auch beim App-Start einmal aufrufen, damit Importe repariert werden,
    /// die eingetroffen sind, während die App geschlossen war.
    func handleRemoteChanges() async {
        do {
            let didDedupe = try CloudDeduplicator.dedupe(in: modelContext)
            print("☁️ CloudSyncObserver: verarbeitet, Dedup \(didDedupe ? "hat aufgeräumt" : "ohne Befund")")
        } catch {
            print("⚠️ Dedup nach CloudKit-Import fehlgeschlagen: \(error)")
        }

        refreshContextFromStore()
        WidgetRefresher.reload()
        NotificationCenter.default.post(name: .dawnyDidReset, object: nil)
    }

    /// Der Import landet im Store, aber bereits geladene Objekte behalten im Kontext ihre
    /// alten Beziehungen. Die Backlog-Liste liest über `Backlog.tasks` (siehe
    /// `Backlog.backlogTasks`) und zeigt eine importierte Aufgabe deshalb erst nach einem
    /// Neustart — fetchbasierte Listen wie Heute sind sofort aktuell. `rollback()` wirft
    /// den Objekt-Cache weg, danach liest alles frisch aus dem Store.
    ///
    /// Eigene ungespeicherte Änderungen würde der Rollback mitnehmen, deshalb werden sie
    /// vorher gesichert.
    private func refreshContextFromStore() {
        if modelContext.hasChanges {
            do {
                try modelContext.save()
            } catch {
                // Nicht speicherbar heißt: lieber veraltet anzeigen als Eingaben verlieren.
                print("⚠️ Speichern vor dem Kontext-Refresh fehlgeschlagen: \(error)")
                return
            }
        }
        modelContext.rollback()
        print("☁️ CloudSyncObserver: Kontext-Cache verworfen")
    }
}
