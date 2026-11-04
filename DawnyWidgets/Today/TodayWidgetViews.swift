// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  TodayWidgetViews.swift
//  DawnyWidgets
//

import SwiftUI
import WidgetKit
import AppIntents

struct TodayWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodayEntry

    var body: some View {
        switch entry.state {
        case .needsAppLaunch:
            WidgetNeedsLaunchView(iconName: "sun.max.fill")
        case .resetPending:
            TodayResetPendingView()
        case .normal(let snapshot):
            content(snapshot)
        }
    }

    @ViewBuilder
    private func content(_ snapshot: TodaySnapshot) -> some View {
        switch family {
        case .systemSmall:
            TodaySmallView(snapshot: snapshot)
        case .systemLarge:
            TodayLargeView(snapshot: snapshot, hint: entry.resetHint)
        case .accessoryRectangular:
            TodayAccessoryRectangularView(snapshot: snapshot)
        case .accessoryCircular:
            TodayAccessoryCircularView(snapshot: snapshot)
        default:
            TodayMediumView(snapshot: snapshot, hint: entry.resetHint)
        }
    }
}

// MARK: - Header

private struct TodayHeader: View {
    let snapshot: TodaySnapshot
    var body: some View {
        WidgetHeader(
            iconName: "sun.max.fill",
            iconColor: DawnyWidgetColor.accent,
            title: WidgetStrings.today,
            trailing: WidgetStrings.progress(done: snapshot.completedCount, total: snapshot.totalCount)
        )
    }
}

// MARK: - Small

private struct TodaySmallView: View {
    let snapshot: TodaySnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TodayHeader(snapshot: snapshot)
            Text(WidgetStrings.openCount(snapshot.openCount))
                .font(DawnyWidgetFont.bigCounter)
                .tracking(-0.7)
                .monospacedDigit()
                .foregroundStyle(.primary)
            ForEach(snapshot.openTasks.prefix(2)) { task in
                HStack(spacing: 8) {
                    WidgetCheckCircle(isDone: false)
                        .scaleEffect(0.85)
                    Text(task.title)
                        .font(DawnyWidgetFont.taskTitle)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                }
            }
            Spacer(minLength: 0)
            WidgetFooterHint(iconName: "moon.fill", text: WidgetStrings.resetAt(hour: snapshot.resetHour))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(DawnyDeepLink.today)
    }
}

// MARK: - Medium

private struct TodayMediumView: View {
    let snapshot: TodaySnapshot
    let hint: ResetHintMode

    private var rows: [WidgetTask] {
        Array((snapshot.openTasks + snapshot.completedTasks).prefix(4))
    }
    private var overflow: Int {
        max(0, snapshot.totalCount - rows.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4.5) {
            TodayHeader(snapshot: snapshot)
            ForEach(rows) { task in
                TodayTaskRow(task: task, showArchiveSymbol: hint == .perTaskSymbol)
            }
            Spacer(minLength: 0)
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var footer: some View {
        if hint == .footerLine {
            WidgetFooterHint(
                iconName: "moon.fill",
                text: String(
                    localized: "widget.today.footerhint",
                    defaultValue: "Offene Aufgaben wandern nachts zurück oder ins Archiv"
                )
            )
        } else if overflow > 0 {
            Text(WidgetStrings.moreCount(overflow))
                .font(DawnyWidgetFont.meta)
                .foregroundStyle(.tertiary)
        }
    }
}

/// Interaktive Aufgabenzeile mit abhakbarer Checkbox.
private struct TodayTaskRow: View {
    let task: WidgetTask
    let showArchiveSymbol: Bool

    var body: some View {
        HStack(spacing: 9) {
            Toggle(isOn: task.isCompleted, intent: ToggleTaskDoneIntent(taskID: task.id)) {
                Text(task.title)
                    .font(DawnyWidgetFont.taskTitle)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(1)
            }
            .toggleStyle(WidgetCheckboxToggleStyle())

            Spacer(minLength: 0)

            if showArchiveSymbol && task.willArchiveAtNextReset {
                Image(systemName: "archivebox")
                    .font(.system(size: 12))
                    .foregroundStyle(DawnyWidgetColor.accent)
            }
        }
        .padding(.vertical, 0.5)
    }
}

// MARK: - Large

private struct TodayLargeView: View {
    let snapshot: TodaySnapshot
    let hint: ResetHintMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TodayHeader(snapshot: snapshot)
            progressBar
            if !snapshot.openTasks.isEmpty {
                sectionLabel(WidgetStrings.sectionOpen)
                ForEach(snapshot.openTasks.prefix(5)) { task in
                    TodayTaskRow(task: task, showArchiveSymbol: hint == .perTaskSymbol)
                }
            }
            if !snapshot.completedTasks.isEmpty {
                sectionLabel(WidgetStrings.sectionDone)
                ForEach(snapshot.completedTasks.prefix(3)) { task in
                    TodayTaskRow(task: task, showArchiveSymbol: false)
                }
            }
            Spacer(minLength: 0)
            WidgetFooterHint(iconName: "moon.fill", text: WidgetStrings.resetAt(hour: snapshot.resetHour))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            let fraction = snapshot.totalCount == 0 ? 0 : Double(snapshot.completedCount) / Double(snapshot.totalCount)
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.tertiarySystemFill))
                Capsule()
                    .fill(DawnyWidgetColor.progressGradient)
                    .frame(width: max(4, geo.size.width * fraction))
            }
        }
        .frame(height: 4)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DawnyWidgetFont.sectionLabel)
            .tracking(0.5)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Lock Screen

private struct TodayAccessoryRectangularView: View {
    let snapshot: TodaySnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(WidgetStrings.today) · \(snapshot.completedCount)/\(snapshot.totalCount)")
                .font(.headline)
            ForEach(snapshot.openTasks.prefix(2)) { task in
                Text(task.title).font(.caption).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetAccentable()
    }
}

private struct TodayAccessoryCircularView: View {
    let snapshot: TodaySnapshot
    var body: some View {
        Gauge(value: Double(snapshot.completedCount), in: 0...Double(max(1, snapshot.totalCount))) {
            Text(WidgetStrings.sectionOpen)
        } currentValueLabel: {
            Text("\(snapshot.openCount)").monospacedDigit()
        }
        .gaugeStyle(.accessoryCircular)
    }
}

// MARK: - Reset Pending

private struct TodayResetPendingView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 24))
                .foregroundStyle(DawnyWidgetColor.accent)
            Text(WidgetStrings.tidied)
                .font(DawnyWidgetFont.meta)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(DawnyDeepLink.today)
    }
}
