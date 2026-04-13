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
