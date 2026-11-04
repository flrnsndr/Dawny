// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  BacklogWidgetViews.swift
//  DawnyWidgets
//

import SwiftUI
import WidgetKit
import AppIntents

struct BacklogWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BacklogEntry

    var body: some View {
        switch entry.state {
        case .needsAppLaunch:
            WidgetNeedsLaunchView(iconName: "tray")
        case .normal(let snapshot):
            content(snapshot)
        }
    }

    @ViewBuilder
    private func content(_ snapshot: BacklogSnapshot) -> some View {
        switch family {
        case .systemSmall:
            BacklogSmallView(snapshot: snapshot)
        case .systemLarge:
            BacklogLargeView(snapshot: snapshot)
        default:
            BacklogMediumView(
                snapshot: snapshot,
                showNavigation: entry.showNavigation,
                configuredCategoryID: entry.configuredCategoryID
            )
        }
    }
}

/// „+"-Knopf: verschiebt eine Backlog-Aufgabe nach Heute (bestehender Intent).
private func moveToTodayButton(for task: WidgetTask) -> some View {
    let intent = MoveTaskToTodayIntent()
    intent.task = TaskAppEntity(id: task.id, displayName: task.title)
    return Button(intent: intent) {
        Image(systemName: "plus")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(DawnyWidgetColor.accent)
            .frame(width: 20, height: 20)
            .background(DawnyWidgetColor.accent.opacity(0.16), in: Circle())
    }
    .buttonStyle(.plain)
}

// MARK: - Small

private struct BacklogSmallView: View {
    let snapshot: BacklogSnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WidgetHeader(iconName: "tray", iconColor: DawnyWidgetColor.backlogTint, title: WidgetStrings.backlog)
            Text("\(snapshot.totalCount)")
                .font(DawnyWidgetFont.bigCounter)
                .tracking(-0.7)
                .monospacedDigit()
            Text(String(localized: "widget.backlog.tasks.label", defaultValue: "Aufgaben"))
                .font(DawnyWidgetFont.meta)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            ForEach(snapshot.sections.prefix(3)) { section in
                HStack(spacing: 6) {
                    Image(systemName: section.iconName)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(width: 14)
                    Text(section.name)
                        .font(DawnyWidgetFont.meta)
                        .lineLimit(1)
                    Spacer(minLength: 2)
                    Text("\(section.openCount)")
                        .font(DawnyWidgetFont.meta)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(DawnyDeepLink.backlog)
    }
}

// MARK: - Medium

private struct BacklogMediumView: View {
    let snapshot: BacklogSnapshot
    let showNavigation: Bool
    let configuredCategoryID: UUID?

    private var section: WidgetCategorySection? {
        guard !snapshot.sections.isEmpty else { return nil }
        if showNavigation {
            let index = min(max(0, snapshot.selectedSectionIndex), snapshot.sections.count - 1)
            return snapshot.sections[index]
        }
        if let id = configuredCategoryID, let match = snapshot.sections.first(where: { $0.id == id }) {
            return match
        }
        return snapshot.sections.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let section {
                WidgetHeader(
                    iconName: section.iconName,
                    iconColor: DawnyWidgetColor.backlogTint,
                    title: section.name,
                    trailing: "\(section.openCount)"
                )
                if showNavigation {
                    BacklogChipBar(sections: snapshot.sections, selectedIndex: snapshot.selectedSectionIndex)
                }
                ForEach(section.tasks.prefix(3)) { task in
                    HStack(spacing: 9) {
                        Text(task.title)
                            .font(DawnyWidgetFont.taskTitle)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        moveToTodayButton(for: task)
                    }
                }
                Spacer(minLength: 0)
                if section.openCount > 3 {
                    Text(WidgetStrings.moreInCategory(section.openCount - 3, category: section.name))
                        .font(DawnyWidgetFont.meta)
                        .foregroundStyle(.tertiary)
                }
            } else {
                BacklogEmptyState()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Chevron-Navigation + Kategorie-Chips (nur wenn `showNavigation`).
private struct BacklogChipBar: View {
    let sections: [WidgetCategorySection]
    let selectedIndex: Int

    var body: some View {
        HStack(spacing: 6) {
            chevron(.backward, systemName: "chevron.left")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        Text(section.name)
                            .font(DawnyWidgetFont.footer)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                index == selectedIndex ? DawnyWidgetColor.accent : Color(.quaternarySystemFill),
                                in: Capsule()
                            )
                            .foregroundStyle(index == selectedIndex ? Color.white : Color.primary)
                    }
                }
            }
            chevron(.forward, systemName: "chevron.right")
        }
    }

    private func chevron(_ direction: CycleDirection, systemName: String) -> some View {
        Button(intent: CycleBacklogCategoryIntent(direction: direction)) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 22)
                .background(Color(.quaternarySystemFill), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Large

private struct BacklogLargeView: View {
    let snapshot: BacklogSnapshot

    /// Zeilen-Budget über alle Kategorien (Header + Tasks) grob begrenzen.
    private var visibleSections: [WidgetCategorySection] {
        Array(snapshot.sections.prefix(4))
    }
    private var shownTaskCount: Int {
        visibleSections.reduce(0) { $0 + min($1.tasks.count, 3) }
    }
    private var overflow: Int {
        max(0, snapshot.totalCount - shownTaskCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetHeader(
                iconName: "tray",
                iconColor: DawnyWidgetColor.backlogTint,
                title: WidgetStrings.backlog,
                trailing: "\(snapshot.totalCount)"
            )
            ForEach(visibleSections) { section in
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: section.iconName)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(section.name)
                            .font(DawnyWidgetFont.sectionLabel)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(section.tasks.prefix(3)) { task in
                        HStack(spacing: 9) {
                            Text(task.title)
                                .font(DawnyWidgetFont.taskTitle)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            moveToTodayButton(for: task)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
            if overflow > 0 {
                Text(WidgetStrings.moreInBacklog(overflow))
                    .font(DawnyWidgetFont.meta)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Empty

private struct BacklogEmptyState: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "tray")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
            Text(String(localized: "widget.backlog.empty", defaultValue: "Backlog ist leer"))
                .font(DawnyWidgetFont.meta)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
