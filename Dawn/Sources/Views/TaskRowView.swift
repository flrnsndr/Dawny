//
//  TaskRowView.swift
//  Dawn
//
//  Einzelne Task-Zeile
//

import SwiftUI

struct TaskRowView: View {
    let task: Task
    let onToggle: (() -> Void)?
    let onDelete: (() -> Void)?
    
    @State private var showingDetail = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            if let toggle = onToggle {
                Button {
                    HapticFeedback.success()
                    toggle()
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(task.isCompleted ? .green : .gray)
                }
                .buttonStyle(.plain)
            }
            
            // Task Content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                // Status Badges
                HStack(spacing: 8) {
                    if task.isSyncedToCalendar {
                        Label("Kalender", systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                    
                    Text(task.status.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundStyle(statusColor)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Chevron for detail
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetail = true
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let delete = onDelete {
                Button(role: .destructive) {
                    HapticFeedback.heavy()
                    delete()
                } label: {
                    Label("Löschen", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showingDetail) {
            TaskDetailView(task: task)
        }
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
}

// MARK: - Task Detail View

struct TaskDetailView: View {
    let task: Task
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Details") {
                    LabeledContent("Titel", value: task.title)
                    
                    if let notes = task.notes {
                        LabeledContent("Notizen") {
                            Text(notes)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    LabeledContent("Status", value: task.status.displayName)
                    
                    if task.isSyncedToCalendar {
                        LabeledContent("Kalender", value: "Synchronisiert")
                    }
                }
                
                Section("Zeitstempel") {
                    LabeledContent("Erstellt", value: task.createdAt.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Geändert", value: task.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
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
    
    return TaskRowView(
        task: task,
        onToggle: {},
        onDelete: {}
    )
    .padding()
}
