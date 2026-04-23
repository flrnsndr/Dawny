// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  TaskRowView.swift
//  Dawny
//
//  Einzelne Task-Zeile
//

import SwiftUI
import SwiftData

/// Zeilen-Wrapper: löst `Task` über `ModelContext.registeredModel` auf. So wird nie auf ein
/// SwiftData-Objekt gelesen, das bereits aus dem Kontext getrennt ist (Fatal:
/// "backing data was detached …" / `Task.status`-Getter).
struct TaskRowView: View {
    let task: Task
    let onToggle: (() -> Void)?
    let onDelete: (() -> Void)?
    let showDragHandle: Bool
    let showBacklogBadge: Bool
    /// Wenn `false`, kein „wiederkehrend“-Symbol in der Zeile (z. B. Backlog – Kategorie zeigt es im Header).
    let showRecurringTaskBadge: Bool
    let showsDisabledToggle: Bool
    @Binding var focusedTaskID: UUID?
    let onSaveTitle: ((String) -> Void)?

    @Environment(\.modelContext) private var modelContext

    init(
        task: Task,
        onToggle: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        showDragHandle: Bool = false,
        showBacklogBadge: Bool = true,
        showRecurringTaskBadge: Bool = true,
        showsDisabledToggle: Bool = false,
        focusedTaskID: Binding<UUID?> = .constant(nil),
        onSaveTitle: ((String) -> Void)? = nil
    ) {
        self.task = task
        self.onToggle = onToggle
        self.onDelete = onDelete
        self.showDragHandle = showDragHandle
        self.showBacklogBadge = showBacklogBadge
        self.showRecurringTaskBadge = showRecurringTaskBadge
        self.showsDisabledToggle = showsDisabledToggle
        _focusedTaskID = focusedTaskID
        self.onSaveTitle = onSaveTitle
    }

    var body: some View {
        if let resolved: Task = modelContext.registeredModel(for: task.persistentModelID),
           resolved.modelContext != nil,
           !resolved.isDeleted {
            TaskRowContent(
                task: resolved,
                onToggle: onToggle,
                onDelete: onDelete,
                showDragHandle: showDragHandle,
                showBacklogBadge: showBacklogBadge,
                showRecurringTaskBadge: showRecurringTaskBadge,
                showsDisabledToggle: showsDisabledToggle,
                focusedTaskID: $focusedTaskID,
                onSaveTitle: onSaveTitle
            )
        } else {
            EmptyView()
        }
    }
}

// MARK: - Row content (gültiger SwiftData-`Task`)

private struct TaskRowContent: View {
    let task: Task
    let onToggle: (() -> Void)?
    let onDelete: (() -> Void)?
    let showDragHandle: Bool
    let showBacklogBadge: Bool
    let showRecurringTaskBadge: Bool
    let showsDisabledToggle: Bool
    @Binding var focusedTaskID: UUID?
    let onSaveTitle: ((String) -> Void)?

    @State private var showingDetail = false
    @State private var titleDraft: String = ""
    @FocusState private var isTitleFieldFocused: Bool

    init(
        task: Task,
        onToggle: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        showDragHandle: Bool = false,
        showBacklogBadge: Bool = true,
        showRecurringTaskBadge: Bool = true,
        showsDisabledToggle: Bool = false,
        focusedTaskID: Binding<UUID?> = .constant(nil),
        onSaveTitle: ((String) -> Void)? = nil
    ) {
        self.task = task
        self.onToggle = onToggle
        self.onDelete = onDelete
        self.showDragHandle = showDragHandle
        self.showBacklogBadge = showBacklogBadge
        self.showRecurringTaskBadge = showRecurringTaskBadge
        self.showsDisabledToggle = showsDisabledToggle
        _focusedTaskID = focusedTaskID
        self.onSaveTitle = onSaveTitle
    }

    var body: some View {
        // Defensive Guard: SwiftUI kann `TaskRowContent.body` direkt erneut auslösen
        // (Observation-Event auf `task`), ohne dass `TaskRowView.body` erneut läuft.
        // Der hier gehaltene `let task: Task` kann dann auf ein Objekt zeigen, dessen
        // SwiftData-Backing bereits detached ist → Zugriff auf `task.status` etc.
        // crasht („backing data was detached"). `modelContext` / `isDeleted` zu lesen
        // ist dagegen safe und liefert `nil`/`false` bei detachedem Backing.
        if task.modelContext != nil, !task.isDeleted {
            return AnyView(liveRow)
        } else {
            return AnyView(EmptyView())
        }
    }

    private var liveRow: some View {
        return buildRowStack()
            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
            .modifier(TrailingSwipeDeleteModifier(onDelete: onDelete))
            .sheet(isPresented: $showingDetail) {
                TaskDetailView(task: task)
            }
    }

    private func buildRowStack() -> some View {
        HStack(spacing: horizontalSpacing) {
            // Drag Handle
            if showDragHandle {
                Image(systemName: "line.3.horizontal")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.trailing, 4)
            }
            
            if let toggle = onToggle {
                Button {
                    HapticFeedback.success()
                    toggle()
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(checkboxFont)
                        .foregroundStyle(task.isCompleted ? .green : .gray)
                        .frame(minWidth: 32, minHeight: 32)
                }
                .buttonStyle(.plain)
            } else if showsDisabledToggle {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle.dashed")
                    .font(checkboxFont)
                    .foregroundStyle(.gray)
                    .frame(minWidth: 32, minHeight: 32)
                    .opacity(0.5)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            
            titleAndMetaColumn

            if isEditingTitle {
                infoButton
            }
        }
        .padding(.vertical, verticalPadding)
        .contentShape(Rectangle())
        .onTapGesture {
            beginTitleEditing()
        }
        .onAppear {
            titleDraft = task.title
        }
        .onChange(of: focusedTaskID) { oldValue, newValue in
            if oldValue == task.id && newValue != task.id {
                commitTitleIfNeeded()
            }

            if newValue == task.id {
                titleDraft = task.title
                DispatchQueue.main.async {
                    isTitleFieldFocused = true
                }
            }
        }
    }

    @ViewBuilder
    private var titleAndMetaColumn: some View {
        let column = VStack(alignment: .leading, spacing: contentSpacing) {
            Group {
                if isEditingTitle {
                    TextField("", text: $titleDraft)
                        .font(titleFont)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .submitLabel(.done)
                        .focused($isTitleFieldFocused)
                        .onSubmit {
                            commitTitleAndEndEditing()
                        }
                        .onChange(of: isTitleFieldFocused) { oldValue, newValue in
                            if oldValue, !newValue {
                                commitTitleAndEndEditing()
                            }
                        }
                } else {
                    Text(task.title)
                        .font(titleFont)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                }
            }
            
            if shouldShowNotes, let notes = task.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(notesLineLimit)
            }
            
            if shouldShowBadges {
                HStack(spacing: 6) {
                    if task.isSyncedToCalendar {
                        Label(String(localized: "task.calendar.badge", defaultValue: "Calendar"), systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }

                    if task.isRecurring, showRecurringTaskBadge {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(
                                String(
                                    localized: "task.recurring.badge",
                                    defaultValue: "Recurring"
                                )
                            )
                    }
                    
                    if shouldShowStatusBadge {
                        Text(task.status.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(statusColor.opacity(0.2))
                            .foregroundStyle(statusColor)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        
        column
    }

    private var infoButton: some View {
        Button {
            if isEditingTitle {
                commitTitleAndEndEditing()
            }
            showingDetail = true
        } label: {
            Image(systemName: "info.circle")
                .font(.title3)
                .foregroundStyle(.blue)
            .frame(minWidth: 32, minHeight: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "task.info.button", defaultValue: "Task details"))
    }

    private var isEditingTitle: Bool {
        focusedTaskID == task.id
    }

    private func beginTitleEditing() {
        titleDraft = task.title
        focusedTaskID = task.id
        DispatchQueue.main.async {
            isTitleFieldFocused = true
        }
    }

    private func commitTitleAndEndEditing() {
        commitTitleIfNeeded()
        if focusedTaskID == task.id {
            focusedTaskID = nil
        }
    }

    private func commitTitleIfNeeded() {
        let trimmed = titleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            titleDraft = task.title
            return
        }

        if trimmed != task.title {
            onSaveTitle?(trimmed)
        }
        titleDraft = trimmed
    }
    
    private var statusColor: Color {
        switch task.status {
        case .inBacklog:
            return .gray
        case .scheduled:
            return .blue
        case .dailyFocus:
            return .orange
        case .completed:
            return .green
        }
    }
    
    private var shouldShowStatusBadge: Bool {
        task.status != .inBacklog || showBacklogBadge
    }
    
    // MARK: - Compact Styling Properties
    
    /// Horizontal spacing zwischen Elementen
    private var horizontalSpacing: CGFloat {
        task.isCompleted ? 6 : 10
    }
    
    /// Vertical padding der gesamten Zeile
    private var verticalPadding: CGFloat {
        task.isCompleted ? 1 : 2
    }
    
    /// Schriftgröße für den Titel
    private var titleFont: Font {
        task.isCompleted ? .subheadline : .body
    }
    
    /// Schriftgröße für die Checkbox
    private var checkboxFont: Font {
        task.isCompleted ? .callout : .title3
    }
    
    /// Spacing innerhalb des Content-VStacks
    private var contentSpacing: CGFloat {
        task.isCompleted ? 2 : 4
    }
    
    /// Notizen werden in der Zeile bewusst nicht mehr angezeigt – nur im Detail.
    private var shouldShowNotes: Bool {
        false
    }
    
    /// Line limit für Notizen bei erledigten Tasks
    private var notesLineLimit: Int {
        task.isCompleted ? 1 : 2
    }
    
    /// Sollten Badges angezeigt werden?
    private var shouldShowBadges: Bool {
        !task.isCompleted
            || task.isSyncedToCalendar
            || (task.isRecurring && showRecurringTaskBadge)
    }
}

// MARK: - Swipe

private struct TrailingSwipeDeleteModifier: ViewModifier {
    let onDelete: (() -> Void)?
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if let onDelete {
            content.swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    HapticFeedback.heavy()
                    onDelete()
                } label: {
                    Label(String(localized: "task.delete", defaultValue: "Delete"), systemImage: "trash")
                }
            }
        } else {
            content
        }
    }
}

// MARK: - Task Detail View

struct TaskDetailView: View {
    let task: Task
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let resolved: Task = modelContext.registeredModel(for: task.persistentModelID) {
            detailList(for: resolved)
        } else {
            Color.clear
                .onAppear { dismiss() }
        }
    }

    @ViewBuilder
    private func detailList(for task: Task) -> some View {
        NavigationStack {
            List {
                Section(String(localized: "task.detail.section", defaultValue: "Details")) {
                    LabeledContent(String(localized: "task.detail.title.label", defaultValue: "Title"), value: task.title)

                    if let notes = task.notes {
                        LabeledContent(String(localized: "task.detail.notes.label", defaultValue: "Notes")) {
                            Text(notes)
                                .foregroundStyle(.secondary)
                        }
                    }

                    LabeledContent(String(localized: "task.detail.status.label", defaultValue: "Status"), value: task.status.displayName)

                    if task.isSyncedToCalendar {
                        LabeledContent(String(localized: "task.detail.calendar.label", defaultValue: "Calendar"), value: String(localized: "task.detail.calendar.synced", defaultValue: "Synced"))
                    }
                }

                Section(String(localized: "task.detail.timestamps.section", defaultValue: "Timestamps")) {
                    LabeledContent(String(localized: "task.detail.created.label", defaultValue: "Created"), value: task.createdAt.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent(String(localized: "task.detail.modified.label", defaultValue: "Modified"), value: task.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                }
            }
            .navigationTitle(String(localized: "task.detail.title", defaultValue: "Task Details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "task.detail.done", defaultValue: "Done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let schema = Schema([Task.self, Backlog.self, Category.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let backlog = Backlog(title: "Preview", orderIndex: 0)
    let task = Task(
        title: "Sample Task",
        notes: "This is a sample task with some notes",
        status: .dailyFocus,
        parentBacklogID: backlog.id
    )
    task.backlog = backlog
    container.mainContext.insert(backlog)
    container.mainContext.insert(task)
    try? container.mainContext.save()

    return TaskRowView(
        task: task,
        onToggle: {},
        onDelete: {},
        showDragHandle: true
    )
    .modelContainer(container)
    .padding()
}
