//
//  BacklogView.swift
//  Dawny
//
//  View für Backlog-Management
//

import SwiftUI
import SwiftData

struct BacklogView: View {
    @Bindable var viewModel: BacklogViewModel
    var dailyFocusViewModel: DailyFocusViewModel? = nil
    @Bindable var settings: AppSettings = .shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.syncEngine) private var syncEngine
    @Environment(\.selectTodayTab) private var selectTodayTab
    
    @State private var showingAddTask = false
    @State private var showingSettings = false
    @State private var expandedCategories: Set<UUID> = []
    /// Bearbeiten: Reorder-Griffe (`onMove`); außerhalb Bearbeiten: Drag & Drop zwischen Kategorien auf Sektions-Header.
    @State private var editMode = EditMode.inactive
    
    private var quickAddDefaultCategoryID: UUID? {
        let sorted = viewModel.categories.sorted()
        return sorted.first { $0.categoryType == settings.defaultCategoryType }?.id ?? sorted.first?.id
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.backlogTasks.isEmpty {
                    emptyStateView
                } else {
                    if settings.showCategories {
                        categorizedTaskListView
                    } else {
                        uncategorizedTaskListView
                    }
                }
            }
            .navigationTitle(viewModel.currentBacklog?.title ?? String(localized: "backlog.title", defaultValue: "Backlog"))
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !viewModel.backlogTasks.isEmpty {
                        Button {
                            toggleEditMode()
                        } label: {
                            Text(editMode == .active
                                 ? String(localized: "common.done", defaultValue: "Fertig")
                                 : String(localized: "common.edit", defaultValue: "Bearbeiten"))
                        }
                    }
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                QuickAddView(
                    categories: settings.showCategories ? viewModel.categories.sorted() : [],
                    defaultCategoryID: quickAddDefaultCategoryID,
                    onSave: { title, notes, category in
                        viewModel.addTask(title: title, notes: notes, category: category)
                    }
                )
                .onAppear {
                    if settings.showCategories {
                        viewModel.loadCategories()
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                viewModel.loadBacklogs()
                viewModel.loadCategories()
                initializeExpandedCategories()
                
                // Migration: Wenn Kategorien aktiviert sind, migriere Tasks ohne Kategorie
                if settings.showCategories {
                    viewModel.migrateUncategorizedTasksIfNeeded()
                }
            }
            .onChange(of: settings.showCategories) { oldValue, newValue in
                if newValue {
                    // Wenn Kategorien aktiviert werden, migriere Tasks ohne Kategorie
                    viewModel.migrateUncategorizedTasksIfNeeded()
                    viewModel.loadCategories()
                    initializeExpandedCategories()
                }
            }
            .overlay(alignment: .top) {
                if let error = viewModel.errorMessage {
                    ErrorBannerView(message: error) {
                        viewModel.errorMessage = nil
                    }
                    .padding(.top, 8)
                    .onAppear {
                        HapticFeedback.error()
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Kategorisierte Ansicht mit Sections pro Kategorie
    private var categorizedTaskListView: some View {
        let grouped = viewModel.groupedTasks
        let sortedCategories = viewModel.categories.sorted()
        
        return List {
            ForEach(sortedCategories, id: \.id) { category in
                let tasks = grouped[category.id] ?? []
                let isExpanded = expandedCategories.contains(category.id) || (!tasks.isEmpty && !category.isUncategorized)
                
                // Zeige alle Kategorien an (leere werden eingeklappt angezeigt)
                Section {
                    if isExpanded {
                        ForEach(tasks, id: \.id) { task in
                            backlogCategorizedTaskRow(task: task)
                        }
                        .onMove { source, destination in
                            viewModel.moveTasksWithinCategory(category: category, from: source, to: destination)
                        }
                    }
                    } header: {
                        CategoryHeaderView(
                            category: category,
                            taskCount: tasks.count,
                            isExpanded: isExpanded
                        ) {
                            toggleCategory(category.id)
                        }
                        .dropDestination(for: BacklogTaskTransfer.self) { items, _ in
                            return handleCategoryHeaderDrop(items, targetCategory: category)
                        }
                    }
            }
        }
        .environment(\.editMode, $editMode)
        .listStyle(.insetGrouped)
    }
    
    /// Unkategorisierte Ansicht (flache Liste)
    private var uncategorizedTaskListView: some View {
        List {
            ForEach(viewModel.backlogTasks, id: \.id) { task in
                backlogUncategorizedRow(task: task)
            }
            .onMove { source, destination in
                viewModel.moveTasks(from: source, to: destination)
            }
        }
        .environment(\.editMode, $editMode)
        .listStyle(.insetGrouped)
    }
    
    @ViewBuilder
    private func backlogUncategorizedRow(task: Task) -> some View {
        let base = TaskRowView(
            task: task,
            onToggle: nil,
            onDelete: {
                _Concurrency.Task {
                    await viewModel.deleteTask(task)
                }
            },
            showBacklogBadge: false,
            listEditingExplicit: editMode == .active
        )
        if editMode == .inactive {
            base.swipeActions(edge: .leading) {
                Button {
                    HapticFeedback.medium()
                    _Concurrency.Task {
                        await viewModel.moveTaskToDailyFocus(task)
                    }
                } label: {
                    Label(String(localized: "backlog.swipe.today", defaultValue: "Heute"), systemImage: "sun.max.fill")
                }
                .tint(.orange)
            }
        } else {
            base
        }
    }
    
    @ViewBuilder
    private func backlogCategorizedTaskRow(task: Task) -> some View {
        let base = TaskRowView(
            task: task,
            onToggle: nil,
            onDelete: {
                _Concurrency.Task {
                    await viewModel.deleteTask(task)
                }
            },
            showBacklogBadge: false,
            listEditingExplicit: editMode == .active
        )
        let withContext = base.contextMenu {
            categoryContextMenu(for: task)
        }
        let withLeadingSwipe: some View = Group {
            if editMode == .inactive {
                withContext.swipeActions(edge: .leading) {
                    Button {
                        HapticFeedback.medium()
                        _Concurrency.Task {
                            await viewModel.moveTaskToDailyFocus(task)
                        }
                    } label: {
                        Label(String(localized: "backlog.swipe.today", defaultValue: "Heute"), systemImage: "sun.max.fill")
                    }
                    .tint(.orange)
                }
            } else {
                withContext
            }
        }
        
        if editMode == .inactive {
            withLeadingSwipe.draggable(BacklogTaskTransfer(taskID: task.id))
        } else {
            withLeadingSwipe
        }
    }
    
    private func toggleEditMode() {
        editMode = editMode == .active ? .inactive : .active
    }
    
    private func handleCategoryHeaderDrop(_ items: [BacklogTaskTransfer], targetCategory: Category) -> Bool {
        guard let payload = items.first,
              let task = viewModel.task(withID: payload.taskID) else { return false }
        if task.category?.id == targetCategory.id { return false }
        viewModel.moveTaskToCategory(task, category: targetCategory, placeAtTopOfCategory: true)
        expandedCategories.insert(targetCategory.id)
        HapticFeedback.light()
        return true
    }
    
    // MARK: - Helper Methods
    
    /// Initialisiert erweiterte Kategorien (alle mit Tasks werden erweitert)
    private func initializeExpandedCategories() {
        let grouped = viewModel.groupedTasks
        for (categoryId, tasks) in grouped {
            if !tasks.isEmpty {
                expandedCategories.insert(categoryId)
            }
        }
    }
    
    /// Toggelt die Erweiterung einer Kategorie
    private func toggleCategory(_ categoryId: UUID) {
        if expandedCategories.contains(categoryId) {
            expandedCategories.remove(categoryId)
        } else {
            expandedCategories.insert(categoryId)
        }
    }
    
    
    /// Context Menu für Kategorieauswahl
    @ViewBuilder
    private func categoryContextMenu(for task: Task) -> some View {
        // Option: Keine Kategorie (nur wenn nicht bereits unkategorisiert)
        if task.category?.isUncategorized != true {
            Button {
                viewModel.moveTaskToCategory(task, category: nil)
            } label: {
                Label(
                    String(localized: "category.menu.uncategorized", defaultValue: "Unkategorisiert"),
                    systemImage: "tag"
                )
            }
        }
        
        Divider()
        
        // Alle verfügbaren Kategorien
        ForEach(viewModel.categories.sorted(), id: \.id) { category in
            Button {
                viewModel.moveTaskToCategory(task, category: category)
            } label: {
                HStack {
                    Image(systemName: category.iconName)
                    Text(category.name)
                    if task.category?.id == category.id {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "tray",
            title: String(localized: "backlog.empty.title", defaultValue: "Backlog ist leer"),
            message: String(localized: "backlog.empty.message", defaultValue: "Füge neue Tasks hinzu, um mit der Planung zu beginnen"),
            actionTitle: String(localized: "backlog.empty.action", defaultValue: "Task hinzufügen"),
            action: {
                showingAddTask = true
            }
        )
    }
}
