// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  ArchiveView.swift
//  Dawny
//
//  Archiv-Tab – zeigt automatisch archivierte Tasks (Make-It-Count) und
//  manuell erledigte Tasks der letzten 30 Tage in getrennten Sektionen.
//

import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Bindable var viewModel: ArchiveViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var isArchiveExpanded: Bool = true
    @State private var isCompletedExpanded: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isEmpty {
                    emptyStateView
                } else {
                    taskList
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                viewModel.loadAll()
                isArchiveExpanded = true
                isCompletedExpanded = false
            }
            .overlay(alignment: .top) {
                if let error = viewModel.errorMessage {
                    ErrorBannerView(message: error) {
                        viewModel.errorMessage = nil
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    // MARK: - Task List

    private var taskList: some View {
        List {
            if !viewModel.archivedTasks.isEmpty {
                Section {
                    if isArchiveExpanded {
                        ForEach(viewModel.archivedTasks, id: \.id) { task in
                            archivedTaskRow(task: task)
                        }
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 2) {
                        ArchiveSectionHeader(
                            title: String(
                                localized: "archive.section.archive.title",
                                defaultValue: "Archived"
                            ),
                            count: viewModel.archivedTasks.count,
                            isExpanded: isArchiveExpanded,
                            onToggle: { isArchiveExpanded.toggle() }
                        )
                        if isArchiveExpanded {
                            Text(
                                String(
                                    localized: "archive.section.header",
                                    defaultValue: "Archived tasks can be reactivated or deleted."
                                )
                            )
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                            .padding(.top, 2)
                        }
                    }
                }
            }

            if !viewModel.completedTasks.isEmpty {
                Section {
                    if isCompletedExpanded {
                        ForEach(viewModel.completedTasks, id: \.id) { task in
                            completedTaskRow(task: task)
                        }
                    }
                } header: {
                    ArchiveSectionHeader(
                        title: String(
                            localized: "archive.section.completed.title",
                            defaultValue: "Completed"
                        ),
                        count: viewModel.completedTasks.count,
                        isExpanded: isCompletedExpanded,
                        onToggle: { isCompletedExpanded.toggle() }
                    )
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Archived Row

    private func archivedTaskRow(task: Task) -> some View {
        ArchivedTaskRowView(
            task: task,
            onUnarchiveToBacklog: { viewModel.unarchiveToBacklog(taskID: task.id) },
            onUnarchiveToDailyFocus: { viewModel.unarchiveToDailyFocus(taskID: task.id) },
            onDelete: { viewModel.deleteTask(taskID: task.id) }
        )
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                viewModel.unarchiveToBacklog(taskID: task.id)
            } label: {
                Label(
                    String(localized: "archive.swipe.backlog", defaultValue: "Backlog"),
                    systemImage: "tray.fill"
                )
            }
            .tint(.blue)

            Button {
                viewModel.unarchiveToDailyFocus(taskID: task.id)
            } label: {
                Label(
                    String(localized: "archive.swipe.today", defaultValue: "Today"),
                    systemImage: "sun.max.fill"
                )
            }
            .tint(.orange)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.deleteTask(taskID: task.id)
            } label: {
                Label(
                    String(localized: "archive.swipe.delete", defaultValue: "Delete"),
                    systemImage: "trash"
                )
            }
        }
    }

    // MARK: - Completed Row

    private func completedTaskRow(task: Task) -> some View {
        CompletedTaskRowView(
            task: task,
            onMoveToBacklog: { viewModel.moveCompletedToBacklog(taskID: task.id) },
            onMoveToDailyFocus: { viewModel.moveCompletedToDailyFocus(taskID: task.id) },
            onDelete: { viewModel.deleteCompletedTask(taskID: task.id) }
        )
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                viewModel.moveCompletedToBacklog(taskID: task.id)
            } label: {
                Label(
                    String(localized: "archive.swipe.backlog", defaultValue: "Backlog"),
                    systemImage: "tray.fill"
                )
            }
            .tint(.blue)

            Button {
                viewModel.moveCompletedToDailyFocus(taskID: task.id)
            } label: {
                Label(
                    String(localized: "archive.swipe.today", defaultValue: "Today"),
                    systemImage: "sun.max.fill"
                )
            }
            .tint(.orange)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.deleteCompletedTask(taskID: task.id)
            } label: {
                Label(
                    String(localized: "archive.swipe.delete", defaultValue: "Delete"),
                    systemImage: "trash"
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "checkmark.seal.fill",
            title: String(localized: "archive.empty.title", defaultValue: "Nothing here!"),
            message: String(
                localized: "archive.empty.message",
                defaultValue: "You're finishing what you start. Your archive is empty – keep it up!"
            )
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Section Header

private struct ArchiveSectionHeader: View {
    let title: String
    let count: Int
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .textCase(nil)

            Spacer()

            Text(count, format: .number)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Capsule())

            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}

// MARK: - Archived Task Row

/// Zeigt einen automatisch archivierten Task ausgegraut an.
private struct ArchivedTaskRowView: View {
    let task: Task
    let onUnarchiveToBacklog: () -> Void
    let onUnarchiveToDailyFocus: () -> Void
    let onDelete: () -> Void

    @State private var isActionDialogPresented: Bool = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if let resolved: Task = modelContext.registeredModel(for: task.persistentModelID),
           resolved.modelContext != nil,
           !resolved.isDeleted {
            rowContent(task: resolved)
        } else {
            EmptyView()
        }
    }

    private func rowContent(task: Task) -> some View {
        HStack(spacing: 12) {
            Button {
                HapticFeedback.light()
                isActionDialogPresented = true
            } label: {
                Image(systemName: "archivebox")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                if let category = task.category {
                    HStack(spacing: 4) {
                        Image(systemName: category.displayIconName)
                            .font(.caption2)
                        Text(category.displayName)
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if let archivedAt = task.archivedAt {
                Text(archivedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(.vertical, 4)
        .opacity(0.75)
        .confirmationDialog(task.title, isPresented: $isActionDialogPresented, titleVisibility: .visible) {
            Button(String(localized: "archive.dialog.move_backlog", defaultValue: "Move to Backlog")) {
                onUnarchiveToBacklog()
            }
            Button(String(localized: "archive.dialog.move_today", defaultValue: "Move to Today")) {
                onUnarchiveToDailyFocus()
            }
            Button(
                String(localized: "archive.dialog.delete", defaultValue: "Delete"),
                role: .destructive
            ) {
                onDelete()
            }
        }
    }
}

// MARK: - Completed Task Row

/// Zeigt einen manuell erledigten Task ausgegraut mit Checkmark-Icon an.
private struct CompletedTaskRowView: View {
    let task: Task
    let onMoveToBacklog: () -> Void
    let onMoveToDailyFocus: () -> Void
    let onDelete: () -> Void

    @State private var isActionDialogPresented: Bool = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if let resolved: Task = modelContext.registeredModel(for: task.persistentModelID),
           resolved.modelContext != nil,
           !resolved.isDeleted {
            rowContent(task: resolved)
        } else {
            EmptyView()
        }
    }

    private func rowContent(task: Task) -> some View {
        HStack(spacing: 12) {
            Button {
                HapticFeedback.light()
                isActionDialogPresented = true
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                if let category = task.category {
                    HStack(spacing: 4) {
                        Image(systemName: category.displayIconName)
                            .font(.caption2)
                        Text(category.displayName)
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if let completedAt = task.completedAt {
                Text(completedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(.vertical, 4)
        .opacity(0.75)
        .confirmationDialog(task.title, isPresented: $isActionDialogPresented, titleVisibility: .visible) {
            Button(String(localized: "archive.dialog.move_backlog", defaultValue: "Move to Backlog")) {
                onMoveToBacklog()
            }
            Button(String(localized: "archive.dialog.move_today", defaultValue: "Move to Today")) {
                onMoveToDailyFocus()
            }
            Button(
                String(localized: "archive.dialog.delete", defaultValue: "Delete"),
                role: .destructive
            ) {
                onDelete()
            }
        }
    }
}
