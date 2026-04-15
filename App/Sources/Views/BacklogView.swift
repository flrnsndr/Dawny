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
    @Environment(\.triggerWelcomeFlow) private var triggerWelcomeFlow
    
    @State private var showingAddTask = false
    @State private var showingSettings = false
    @State private var expandedCategories: Set<UUID> = []
    @State private var showingClearAllConfirm = false
    /// Bearbeiten: Reorder-Griffe (`onMove`); außerhalb Bearbeiten: Drag & Drop zwischen Kategorien auf Sektions-Header.
    @State private var editMode = EditMode.inactive
    
    private var quickAddDefaultCategoryID: UUID? {
        let sorted = viewModel.categories.sorted()
        return sorted.first { $0.categoryType == settings.defaultCategoryType }?.id ?? sorted.first?.id
    }

    private var quickCategory: Category? {
        viewModel.categories.first { $0.categoryType == .quick }
    }

    private var clearAllAction: (() -> Void)? {
        #if DEBUG
        return { showingClearAllConfirm = true }
        #else
        return nil
        #endif
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
                    .accessibilityLabel(String(localized: "settings.title", defaultValue: "Einstellungen"))
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !viewModel.backlogTasks.isEmpty {
                        Button {
                            toggleEditMode()
                        } label: {
                            Text(editMode == .active
                                 ? String(localized: "common.done", defaultValue: "Fertig")
                                 : String(localized: "common.edit", defaultValue: "Bearbeiten"))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                QuickAddView(
                    categories: settings.showCategories ? viewModel.categories.sorted() : [],
                    defaultCategoryID: quickAddDefaultCategoryID,
                    initialDestination: .backlog,
                    onSave: { title, notes, category, destination in
                        switch destination {
                        case .backlog:
                            viewModel.addTask(title: title, notes: notes, category: category)
                        case .today:
                            let forcedCategory = quickCategory ?? category
                            if let newTask = viewModel.addTask(title: title, notes: notes, category: forcedCategory) {
                                _Concurrency.Task {
                                    await viewModel.moveTaskToDailyFocus(newTask)
                                    await MainActor.run {
                                        selectTodayTab()
                                    }
                                }
                            }
                        }
                    }
                )
                .onAppear {
                    if settings.showCategories {
                        viewModel.loadCategories()
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    onRequestAddTestItems: {
                        triggerTestWorkflow()
                    },
                    onRequestDeleteAll: clearAllAction,
                    onRequestShowWelcome: {
                        showingSettings = false
                        triggerWelcomeFlow()
                    }
                )
            }
            #if DEBUG
            .alert(
                String(localized: "quickadd.deleteall", defaultValue: "Alle Tasks löschen"),
                isPresented: $showingClearAllConfirm
            ) {
                Button(String(localized: "quickadd.cancel", defaultValue: "Abbrechen"), role: .cancel) {}
                Button(String(localized: "common.delete", defaultValue: "Löschen"), role: .destructive) {
                    _Concurrency.Task {
                        await clearAllBacklogTasks()
                    }
                }
            } message: {
                Text(String(localized: "backlog.debug.clear.message", defaultValue: "Alle Tasks (Backlog und Heute) werden gelöscht."))
            }
            #endif
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
            .safeAreaInset(edge: .bottom) {
                bottomBarAddControls
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

    private func triggerTestWorkflow() {
        #if DEBUG
        viewModel.addDebugTestItems(settings: settings)
        viewModel.loadBacklogs()
        viewModel.loadCategories()
        initializeExpandedCategories()
        #endif
    }

    private func clearAllBacklogTasks() async {
        #if DEBUG
        let backlogTasks = viewModel.backlogTasks
        let todayTasks = dailyFocusViewModel?.dailyTasks ?? []

        dailyFocusViewModel?.clearTasksFromDisplayOnly()

        for task in backlogTasks {
            await viewModel.deleteTask(task)
        }

        if let dfvm = dailyFocusViewModel {
            for task in todayTasks {
                await dfvm.deleteTask(task)
            }
        }

        viewModel.loadBacklogs()
        viewModel.loadCategories()
        initializeExpandedCategories()
        #endif
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
            message: String(localized: "backlog.empty.message", defaultValue: "Füge neue Tasks hinzu, um mit der Planung zu beginnen")
        )
    }

    private var bottomBarAddControls: some View {
        HStack {
            Button {
                showingAddTask = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 52, height: 52)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
            }
            .accessibilityLabel(String(localized: "backlog.add.task", defaultValue: "Task hinzufügen"))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}
