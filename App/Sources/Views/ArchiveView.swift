// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  ArchiveView.swift
//  Dawny
//
//  Archiv-Tab – zeigt nicht erledigte Tasks, die nach wiederholtem Nicht-Erledigen archiviert wurden.
//

import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Bindable var viewModel: ArchiveViewModel
    @Environment(\.modelContext) private var modelContext

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
                viewModel.loadArchivedTasks()
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
            Section {
                ForEach(viewModel.archivedTasks, id: \.id) { task in
                    archivedTaskRow(task: task)
                }
            } header: {
                Text(
                    String(
                        localized: "archive.section.header",
                        defaultValue: "Archived tasks can be reactivated or deleted."
                    )
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(nil)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Row

    private func archivedTaskRow(task: Task) -> some View {
        ArchivedTaskRowView(
            task: task,
            onUnarchiveToBacklog: {
                viewModel.unarchiveToBacklog(taskID: task.id)
            },
            onUnarchiveToDailyFocus: {
                viewModel.unarchiveToDailyFocus(taskID: task.id)
            },
            onDelete: {
                viewModel.deleteTask(taskID: task.id)
            }
        )
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                viewModel.unarchiveToDailyFocus(taskID: task.id)
            } label: {
                Label(
                    String(localized: "archive.swipe.today", defaultValue: "Today"),
                    systemImage: "sun.max.fill"
                )
            }
            .tint(.orange)

            Button {
                viewModel.unarchiveToBacklog(taskID: task.id)
            } label: {
                Label(
                    String(localized: "archive.swipe.backlog", defaultValue: "Backlog"),
                    systemImage: "tray.fill"
                )
            }
            .tint(.blue)
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

// MARK: - Archived Task Row

/// Zeigt einen archivierten Task ausgegraut an (keine Checkbox, kein Drag-Handle).
private struct ArchivedTaskRowView: View {
    let task: Task
    let onUnarchiveToBacklog: () -> Void
    let onUnarchiveToDailyFocus: () -> Void
    let onDelete: () -> Void

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
            Image(systemName: "archivebox")
                .font(.subheadline)
                .foregroundStyle(.tertiary)

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
    }
}
