//
//  TaskRowView.swift
//  Dawny
//
//  Einzelne Task-Zeile
//

import SwiftUI

struct TaskRowView: View {
    let task: Task
    let onToggle: (() -> Void)?
    let onDelete: (() -> Void)?
    let showDragHandle: Bool
    let showBacklogBadge: Bool
    
    @State private var showingDetail = false
    
    init(
        task: Task,
        onToggle: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        showDragHandle: Bool = false,
        showBacklogBadge: Bool = true
    ) {
        self.task = task
        self.onToggle = onToggle
        self.onDelete = onDelete
        self.showDragHandle = showDragHandle
        self.showBacklogBadge = showBacklogBadge
    }
    
    var body: some View {
        let rowStack = HStack(spacing: horizontalSpacing) {
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
            }
            
            titleAndMetaColumn
            
            Spacer()
        }
        .padding(.vertical, verticalPadding)
        
        rowStack
            .contentShape(Rectangle())
            .onTapGesture {
                showingDetail = true
            }
            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
            .modifier(TrailingSwipeDeleteModifier(onDelete: onDelete))
        .sheet(isPresented: $showingDetail) {
            TaskDetailView(task: task)
        }
    }
    
    @ViewBuilder
    private var titleAndMetaColumn: some View {
        let column = VStack(alignment: .leading, spacing: contentSpacing) {
            Text(task.title)
                .font(titleFont)
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
            
            if shouldShowNotes, let notes = task.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(notesLineLimit)
            }
            
            if shouldShowBadges {
                HStack(spacing: 6) {
                    if task.isSyncedToCalendar {
                        Label(String(localized: "task.calendar.badge", defaultValue: "Kalender"), systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.blue)
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
        !task.isCompleted || task.isSyncedToCalendar
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
                    Label(String(localized: "task.delete", defaultValue: "Löschen"), systemImage: "trash")
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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "task.detail.section", defaultValue: "Details")) {
                    LabeledContent(String(localized: "task.detail.title.label", defaultValue: "Titel"), value: task.title)
                    
                    if let notes = task.notes {
                        LabeledContent(String(localized: "task.detail.notes.label", defaultValue: "Notizen")) {
                            Text(notes)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    LabeledContent(String(localized: "task.detail.status.label", defaultValue: "Status"), value: task.status.displayName)
                    
                    if task.isSyncedToCalendar {
                        LabeledContent(String(localized: "task.detail.calendar.label", defaultValue: "Kalender"), value: String(localized: "task.detail.calendar.synced", defaultValue: "Synchronisiert"))
                    }
                }
                
                Section(String(localized: "task.detail.timestamps.section", defaultValue: "Zeitstempel")) {
                    LabeledContent(String(localized: "task.detail.created.label", defaultValue: "Erstellt"), value: task.createdAt.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent(String(localized: "task.detail.modified.label", defaultValue: "Geändert"), value: task.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                }
            }
            .navigationTitle(String(localized: "task.detail.title", defaultValue: "Task Details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "task.detail.done", defaultValue: "Fertig")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let task = Task(
        title: "Sample Task",
        notes: "This is a sample task with some notes",
        status: .dailyFocus,
        parentBacklogID: UUID()
    )
    
    TaskRowView(
        task: task,
        onToggle: {},
        onDelete: {},
        showDragHandle: true
    )
    .padding()
}
