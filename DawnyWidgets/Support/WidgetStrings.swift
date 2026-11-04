// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  WidgetStrings.swift
//  DawnyWidgets
//
//  Lokalisierte, formatierte Strings für die Widgets (en + de in Localizable.xcstrings).
//

import Foundation

enum WidgetStrings {
    static func openCount(_ n: Int) -> String {
        String(format: String(localized: "widget.today.open.count", defaultValue: "%lld offen"), n)
    }

    static func progress(done: Int, total: Int) -> String {
        String(
            format: String(localized: "widget.today.progress", defaultValue: "%1$lld von %2$lld erledigt"),
            done, total
        )
    }

    static func resetAt(hour: Int) -> String {
        String(format: String(localized: "widget.today.resetat", defaultValue: "Reset um %lld:00"), hour)
    }

    static func moreCount(_ n: Int) -> String {
        String(format: String(localized: "widget.more.count", defaultValue: "+%lld weitere"), n)
    }

    static func moreInCategory(_ n: Int, category: String) -> String {
        String(
            format: String(localized: "widget.more.in.category", defaultValue: "+%1$lld weitere in %2$@"),
            n, category
        )
    }

    static func moreInBacklog(_ n: Int) -> String {
        String(format: String(localized: "widget.more.backlog", defaultValue: "+%lld weitere im Backlog"), n)
    }

    static func newBadge(_ n: Int) -> String {
        String(format: String(localized: "widget.archive.new.badge", defaultValue: "%lld neu"), n)
    }

    static let tidied = String(
        localized: "widget.today.tidied",
        defaultValue: "Deine Heute-Ansicht wurde aufgeräumt — tippe, um deinen Tag zu planen"
    )
    static let openDawny = String(localized: "widget.open.dawny", defaultValue: "Öffne Dawny")
    static let today = String(localized: "widget.today.name", defaultValue: "Heute")
    static let backlog = String(localized: "widget.backlog.name", defaultValue: "Backlog")
    static let archive = String(localized: "widget.archive.name", defaultValue: "Archiv")
    static let sectionOpen = String(localized: "widget.section.open", defaultValue: "OFFEN")
    static let sectionDone = String(localized: "widget.section.done", defaultValue: "ERLEDIGT")
    static let archiveSince = String(localized: "widget.archive.since", defaultValue: "seit dem Reset heute Nacht")
    static let archiveCheckNow = String(localized: "widget.archive.checknow", defaultValue: "Jetzt prüfen")
    static let archiveReactivate = String(
        localized: "widget.archive.reactivate",
        defaultValue: "Zum Reaktivieren in der App öffnen"
    )

    /// Relative Zeit „vor 9 Std." — nutzt das System-Format.
    static func relativeTime(_ date: Date, now: Date = Date()) -> String {
        date.formatted(.relative(presentation: .named))
    }
}
