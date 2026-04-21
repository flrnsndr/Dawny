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

struct BacklogTaskTransfer: Codable, Hashable, Transferable {
    let taskID: UUID

    static var transferRepresentation: some TransferRepresentation {
        // App-interner Drag&Drop-Transfer; kein eigener UTI in der Info.plist notwendig.
        CodableRepresentation(contentType: .data)
    }
}
