// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  BacklogTaskTransfer.swift
//  Dawny
//
//  Transfer-Payload für Drag & Drop (Task-ID); SwiftData-Modelle sind nicht direkt Transferable.
//

import CoreTransferable
import UniformTypeIdentifiers

extension UTType {
    /// App-interner Typ für Backlog-Task-IDs beim Ziehen zwischen Kategorien.
    static var dawnyBacklogTaskID = UTType(exportedAs: "Florian.Dawny.MVP.backlog-task-id")
}

struct BacklogTaskTransfer: Codable, Hashable, Transferable {
    let taskID: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .dawnyBacklogTaskID)
    }
}
