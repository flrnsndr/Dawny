// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

import AppIntents
import SwiftData

/// Hakt eine Aufgabe im Widget ab oder öffnet sie wieder.
///
/// Konform zu `SetValueIntent`, damit ein `Toggle(isOn:intent:)` im Widget die
/// optimistische Häkchen-Animation gratis bekommt. Nutzt rohe UUID-Strings statt
/// `TaskAppEntity`, damit im Widget-Prozess keine Entity-Query nötig ist.
/// Nicht als Siri-Phrase auffindbar — reines Widget-Plumbing.
struct ToggleTaskDoneIntent: AppIntent, SetValueIntent {
    static var title: LocalizedStringResource = "intent.toggledone.title"
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false

    @Parameter(title: "intent.toggledone.param.taskid")
    var taskID: String

    /// Neuer Erledigt-Zustand — vom System beim Umschalten gesetzt (SetValueIntent).
    @Parameter(title: "intent.toggledone.param.value")
    var value: Bool

    init() {}

    init(taskID: UUID, value: Bool = true) {
        self.taskID = taskID.uuidString
        self.value = value
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: taskID) else {
            throw IntentDataStoreError.taskNotFound
        }
        let context = try IntentDataStore.makeContext()
        do {
            if value {
                _ = try IntentDataStore.completeTask(taskID: id, in: context)
            } else {
                _ = try IntentDataStore.uncompleteTask(taskID: id, in: context)
            }
        } catch IntentDataStoreError.taskAlreadyCompleted, IntentDataStoreError.taskArchived {
            // Der Zustand hat sich seit dem Rendern geändert — ein Timeline-Reload
            // (bereits durch die Mutatoren ausgelöst) spiegelt die Realität wider.
        }
        return .result()
    }
}
