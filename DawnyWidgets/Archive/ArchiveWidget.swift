// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  ArchiveWidget.swift
//  DawnyWidgets
//

import SwiftUI
import WidgetKit

struct ArchiveWidget: Widget {
    static let kind = "DawnyArchiveWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: ArchiveProvider()) { entry in
            ArchiveWidgetEntryView(entry: entry)
                .containerBackground(DawnyWidgetColor.cardBackground, for: .widget)
        }
        .configurationDisplayName(Text("widget.archive.name"))
        .description(Text("widget.archive.description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
