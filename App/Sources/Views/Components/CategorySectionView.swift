//
//  CategorySectionView.swift
//  Dawny
//
//  Einklappbare Sektion für eine Kategorie im Backlog
//

import SwiftUI
import UniformTypeIdentifiers

struct CategorySectionView: View {
    let category: TaskCategory
    let tasks: [Task]
    let isCollapsed: Bool
    let onToggleCollapse: () -> Void
    let onDeleteTask: (Task) -> Void
    let onMoveToToday: (Task) -> Void
    let onReorder: (IndexSet, Int) -> Void
    let onChangeCategory: (Task, TaskCategory) -> Void
    
    @State private var isDropTargeted = false
    
    var body: some View {
        Section {
            if !isCollapsed {
                if tasks.isEmpty {
                    emptyStateRow
                } else {
                    taskRows
                }
            }
        } header: {
            categoryHeader
        }
    }
    
    // MARK: - Header
    
    private var categoryHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: category.icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(category.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            
            Text("\(tasks.count)")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(tasks.isEmpty ? Color.secondary.opacity(0.5) : Color.accentColor)
                )
            
            Spacer()
            
            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isDropTargeted ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onToggleCollapse()
        }
    }
    
    // MARK: - Task Rows
    
    private var taskRows: some View {
        ForEach(tasks) { task in
            TaskRowView(
                task: task,
                onToggle: nil,
                onDelete: {
                    onDeleteTask(task)
                },
                showBacklogBadge: false
            )
            .swipeActions(edge: .leading) {
                Button {
                    HapticFeedback.medium()
                    onMoveToToday(task)
                } label: {
                    Label(String(localized: "backlog.swipe.today", defaultValue: "Heute"), systemImage: "sun.max.fill")
                }
                .tint(.orange)
            }
            .contextMenu {
                categoryMenu(for: task)
            }
        }
        .onMove(perform: onReorder)
    }
    
    // MARK: - Category Menu
    
    @ViewBuilder
    private func categoryMenu(for task: Task) -> some View {
        Menu {
            ForEach(TaskCategory.allCases.filter { $0 != category && $0 != .uncategorized }) { targetCategory in
                Button {
                    HapticFeedback.medium()
                    onChangeCategory(task, targetCategory)
                } label: {
                    Label(targetCategory.displayName, systemImage: targetCategory.icon)
                }
            }
        } label: {
            Label(String(localized: "category.move", defaultValue: "In Kategorie verschieben"), systemImage: "folder")
        }
        
        Divider()
        
        Button {
            HapticFeedback.medium()
            onMoveToToday(task)
        } label: {
            Label(String(localized: "backlog.swipe.today", defaultValue: "Heute"), systemImage: "sun.max.fill")
        }
        
        Button(role: .destructive) {
            onDeleteTask(task)
        } label: {
            Label(String(localized: "task.delete", defaultValue: "Löschen"), systemImage: "trash")
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateRow: some View {
        HStack {
            Spacer()
            Text(String(localized: "category.empty", defaultValue: "Keine Tasks"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .italic()
            Spacer()
        }
        .listRowBackground(Color.clear)
    }
}

// MARK: - Draggable Category Header View (für flache Liste)

struct CategoryHeaderDropTarget: View {
    let category: TaskCategory
    let taskCount: Int
    let isCollapsed: Bool
    let onToggleCollapse: () -> Void
    let onDropTask: (Task) -> Void
    
    @State private var isDropTargeted = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category.icon)
                .font(.subheadline)
                .foregroundStyle(isDropTargeted ? .white : .secondary)
                .frame(width: 20)
            
            Text(category.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isDropTargeted ? .white : .primary)
            
            Text("\(taskCount)")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(taskCount == 0 ? Color.secondary.opacity(0.5) : Color.accentColor)
                )
            
            Spacer()
            
            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isDropTargeted ? .white : .secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isDropTargeted ? Color.accentColor : Color(.secondarySystemGroupedBackground))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onToggleCollapse()
        }
        .onDrop(of: [.text], isTargeted: $isDropTargeted) { providers in
            guard let provider = providers.first else { return false }
            
            provider.loadObject(ofClass: NSString.self) { reading, error in
                DispatchQueue.main.async {
                    guard let taskIDString = reading as? String,
                          let taskID = UUID(uuidString: taskIDString),
                          let task = TaskDragRegistry.shared.getTask(for: taskID) else { return }
                    
                    HapticFeedback.medium()
                    onDropTask(task)
                }
            }
            return true
        }
    }
}

// MARK: - Draggable Task Row

struct DraggableTaskRow: View {
    let task: Task
    let onDelete: () -> Void
    let onMoveToToday: () -> Void
    let onChangeCategory: (TaskCategory) -> Void
    let currentCategory: TaskCategory
    
    var body: some View {
        TaskRowView(
            task: task,
            onToggle: nil,
            onDelete: onDelete,
            showBacklogBadge: false
        )
        .swipeActions(edge: .leading) {
            Button {
                HapticFeedback.medium()
                onMoveToToday()
            } label: {
                Label(String(localized: "backlog.swipe.today", defaultValue: "Heute"), systemImage: "sun.max.fill")
            }
            .tint(.orange)
        }
        .draggable(task.id.uuidString) {
            TaskDragRegistry.shared.register(task)
            return Text(task.title)
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 4)
        }
        .contextMenu {
            Menu {
                ForEach(TaskCategory.allCases.filter { $0 != currentCategory && $0 != .uncategorized }) { targetCategory in
                    Button {
                        HapticFeedback.medium()
                        onChangeCategory(targetCategory)
                    } label: {
                        Label(targetCategory.displayName, systemImage: targetCategory.icon)
                    }
                }
            } label: {
                Label(String(localized: "category.move", defaultValue: "In Kategorie verschieben"), systemImage: "folder")
            }
            
            Divider()
            
            Button {
                HapticFeedback.medium()
                onMoveToToday()
            } label: {
                Label(String(localized: "backlog.swipe.today", defaultValue: "Heute"), systemImage: "sun.max.fill")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(String(localized: "task.delete", defaultValue: "Löschen"), systemImage: "trash")
            }
        }
    }
}

// MARK: - Task Drag Registry

/// Registry um Task-Objekte während Drag&Drop zu speichern
final class TaskDragRegistry {
    static let shared = TaskDragRegistry()
    
    private var tasks: [UUID: Task] = [:]
    
    private init() {}
    
    func register(_ task: Task) {
        tasks[task.id] = task
    }
    
    func getTask(for id: UUID) -> Task? {
        tasks[id]
    }
    
    func cleanup() {
        tasks.removeAll()
    }
}
