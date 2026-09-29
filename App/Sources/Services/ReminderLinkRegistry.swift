// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  ReminderLinkRegistry.swift
//  Dawny
//
//  Gerätelokales Verzeichnis der Erinnerungen, die dieses Gerät selbst erreicht hat
//

import Foundation

/// Hält fest, welche Erinnerungs-Verknüpfungen dieses Gerät selbst schon einmal
/// aufgelöst hat.
///
/// `Task.externalReminderID` wandert über iCloud mit, die Erinnerung dahinter nicht
/// zwangsläufig: eine noch nicht migrierte Alt-ID, eine lokale (nicht-iCloud)
/// Erinnerungsliste, ein Exchange-Konto oder eine fehlende EventKit-Berechtigung
/// führen alle dazu, dass ein Zweitgerät zu einer völlig intakten Verknüpfung keine
/// Erinnerung findet. Ohne dieses Verzeichnis liest die `SyncEngine` das als „in der
/// Erinnerungen-App gelöscht" und räumt die Aufgabe aus Heute — eine Änderung, die
/// anschließend zurück auf das verknüpfende Gerät synct.
///
/// Deshalb die Regel: Ein fehlender Treffer beweist eine Löschung nur dann, wenn
/// dieses Gerät die Erinnerung vorher schon einmal in der Hand hatte. Das Verzeichnis
/// liegt bewusst in den gerätelokalen UserDefaults und nicht im synchronisierten
/// Store — es beschreibt, was *dieses* Gerät sehen kann, und ist auf einem anderen
/// Gerät sinnlos.
struct ReminderLinkRegistry {
    /// Gerätelokal, deshalb nicht in `AppSettings.Keys` und nicht in der
    /// App-Group-Migration: Der Schlüssel ist neu, es gibt keinen Altbestand.
    static let storageKey = "DawnyLocallyResolvedReminderIDs"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = AppGroup.defaults) {
        self.defaults = defaults
    }

    /// True, wenn dieses Gerät die Erinnerung schon einmal aufgelöst hat.
    func isKnownLocally(_ reminderID: String) -> Bool {
        storedIDs.contains(reminderID)
    }

    /// Vermerkt, dass dieses Gerät die Erinnerung erreicht hat.
    func remember(_ reminderID: String) {
        var ids = storedIDs
        guard ids.insert(reminderID).inserted else { return }
        write(ids)
    }

    /// Vergisst eine Verknüpfung, deren Erinnerung dieses Gerät gelöscht hat oder
    /// als gelöscht erkannt hat.
    func forget(_ reminderID: String) {
        var ids = storedIDs
        guard ids.remove(reminderID) != nil else { return }
        write(ids)
    }

    /// Wirft alle Einträge weg, zu denen es keine verknüpfte Aufgabe mehr gibt.
    ///
    /// Hält das Verzeichnis auf die Größe der aktiven Verknüpfungen begrenzt. Zu viel
    /// wegzuwerfen ist ungefährlich: Ein vergessener Eintrag macht dieses Gerät nur
    /// vorsichtiger, und der nächste erfolgreiche Abruf trägt ihn wieder ein.
    func keepOnly(_ reminderIDs: Set<String>) {
        let ids = storedIDs
        let kept = ids.intersection(reminderIDs)
        guard kept.count != ids.count else { return }
        write(kept)
    }

    private var storedIDs: Set<String> {
        Set(defaults.stringArray(forKey: Self.storageKey) ?? [])
    }

    private func write(_ ids: Set<String>) {
        defaults.set(Array(ids), forKey: Self.storageKey)
    }
}
