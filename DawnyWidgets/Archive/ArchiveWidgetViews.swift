// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  ArchiveWidgetViews.swift
//  DawnyWidgets
//

import SwiftUI
import WidgetKit

struct ArchiveWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ArchiveEntry

    var body: some View {
        switch entry.state {
        case .needsAppLaunch:
            WidgetNeedsLaunchView(iconName: "archivebox")
        case .normal(let snapshot):
            if family == .systemSmall {
                ArchiveSmallView(snapshot: snapshot)
            } else {
                ArchiveMediumView(snapshot: snapshot)
            }
        }
    }
}

// MARK: - Small

private struct ArchiveSmallView: View {
    let snapshot: ArchiveSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "archivebox")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
                if snapshot.newCount > 0 {
                    Circle()
                        .fill(DawnyWidgetColor.accent)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(DawnyWidgetColor.cardBackground, lineWidth: 2))
                        .offset(x: 4, y: -2)
                }
            }
            Spacer(minLength: 0)
            Text("\(snapshot.newCount)")
                .font(DawnyWidgetFont.bigCounter)
                .tracking(-0.7)
                .monospacedDigit()
            Text(String(localized: "widget.archive.new.label", defaultValue: "neu im Archiv"))
                .font(DawnyWidgetFont.meta)
                .foregroundStyle(.secondary)
            Text(WidgetStrings.archiveSince)
                .font(DawnyWidgetFont.footer)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            Text(WidgetStrings.archiveCheckNow)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DawnyWidgetColor.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(DawnyDeepLink.archive)
    }
}

// MARK: - Medium

private struct ArchiveMediumView: View {
    let snapshot: ArchiveSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "archivebox")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Text(WidgetStrings.archive)
                    .font(DawnyWidgetFont.title)
                Spacer(minLength: 4)
                if snapshot.newCount > 0 {
                    Text(WidgetStrings.newBadge(snapshot.newCount))
                        .font(DawnyWidgetFont.footer)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(DawnyWidgetColor.accent.opacity(0.14), in: Capsule())
                        .foregroundStyle(DawnyWidgetColor.accent)
                }
            }

            ForEach(snapshot.tasks.prefix(3)) { task in
                HStack(spacing: 8) {
                    Circle()
                        .fill(task.isNew ? DawnyWidgetColor.accent : Color.clear)
                        .frame(width: 7, height: 7)
                    Text(task.title)
                        .font(DawnyWidgetFont.taskTitle)
                        .foregroundStyle(.secondary)
                        .opacity(0.85)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    if let archivedAt = task.archivedAt {
                        Text(WidgetStrings.relativeTime(archivedAt))
                            .font(DawnyWidgetFont.footer)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)
            Text(WidgetStrings.archiveReactivate)
                .font(DawnyWidgetFont.footer)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(DawnyDeepLink.archive)
    }
}
