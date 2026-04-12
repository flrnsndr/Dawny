//
//  BacklogView.swift
//  Dawny
//
//  View für Backlog-Management
//

import SwiftUI
import SwiftData
import UIKit

// #region agent log helper
func writeLog(_ data: [String: Any]) {
    let logPath = "/Users/florianschneider/Git/Dawny/.cursor/debug.log"
    guard let logData = try? JSONSerialization.data(withJSONObject: data),
          let logString = String(data: logData, encoding: .utf8) else { return }
    if !FileManager.default.fileExists(atPath: logPath) {
        FileManager.default.createFile(atPath: logPath, contents: nil, attributes: nil)
    }
    guard let fileHandle = FileHandle(forWritingAtPath: logPath) else { return }
    fileHandle.seekToEndOfFile()
    fileHandle.write((logString + "\n").data(using: .utf8) ?? Data())
    fileHandle.closeFile()
}
// #endregion

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
    /// Nur für DEBUG-Clear-Alert; in Release ungenutzt, vermeidet aber #if um @State.
    @State private var showingClearAllConfirm = false
    /// Während Massen-Löschung: Liste ausblenden, damit keine TaskRowView auf detached SwiftData-Tasks zugreift.
    @State private var isBulkDeletingTasks = false
    
    private var quickAddDefaultCategoryID: UUID? {
        let sorted = viewModel.categories.sorted()
        return sorted.first { $0.categoryType == settings.defaultCategoryType }?.id ?? sorted.first?.id
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isBulkDeletingTasks {
                    ProgressView(String(localized: "backlog.debug.clear.progress", defaultValue: "Löschen…"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.backlogTasks.isEmpty {
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    debugToolbarLeadingContent
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
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
            #if DEBUG
            .alert(
                String(localized: "backlog.debug.clear.title", defaultValue: "Alles löschen?"),
                isPresented: $showingClearAllConfirm
            ) {
                Button(String(localized: "backlog.debug.clear.cancel", defaultValue: "Abbrechen"), role: .cancel) {}
                Button(String(localized: "backlog.debug.clear.confirm", defaultValue: "Löschen"), role: .destructive) {
                    _Concurrency.Task { @MainActor in
                        await runClearAll()
                    }
                }
            } message: {
                Text(String(localized: "backlog.debug.clear.message", defaultValue: "Alle Tasks in Dawny werden gelöscht; zu Dawny gehörige Einträge in „Erinnerungen“ werden wie beim normalen Task-Löschen entfernt (kein leeres Löschen der gesamten Erinnerungen-App)."))
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
        }
    }
    
    // MARK: - Toolbar (DEBUG: Workflow + Clear neben Einstellungen)
    
    /// Ein einziger Member – `#if` nur im ViewBuilder-Body, damit der Compiler das Symbol immer findet.
    @ViewBuilder
    private var debugToolbarLeadingContent: some View {
        #if DEBUG
        HStack(spacing: 8) {
            debugCircleToolbarButton(systemName: "gearshape.fill") {
                showingSettings = true
            }
            debugCircleToolbarButton(systemName: "wand.and.stars") {
                _Concurrency.Task {
                    await UITestWorkflowRunner.run(
                        backlogViewModel: viewModel,
                        dailyFocusViewModel: dailyFocusViewModel,
                        settings: settings,
                        selectTodayTab: selectTodayTab
                    )
                }
            }
            .disabled(!settings.showCategories)
            .opacity(settings.showCategories ? 1 : 0.45)
            
            debugCircleToolbarButton(systemName: "trash") {
                showingClearAllConfirm = true
            }
            .disabled(syncEngine == nil)
            .opacity(syncEngine == nil ? 0.45 : 1)
        }
        #else
        Button {
            showingSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
        }
        #endif
    }
    
    #if DEBUG
    private func debugCircleToolbarButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    private func runClearAll() async {
        guard let syncEngine else { return }
        // Backlog-Liste ausblenden + „Heute“-Tab leeren — sonst zeigen andere Tabs noch TaskRowViews auf dieselben SwiftData-Objekte.
        isBulkDeletingTasks = true
        dailyFocusViewModel?.clearTasksFromDisplayOnly()
        await _Concurrency.Task.yield()
        try? await _Concurrency.Task.sleep(nanoseconds: 100_000_000)
        defer { isBulkDeletingTasks = false }
        do {
            try await DebugAppDataCleaner.clearAll(syncEngine: syncEngine, modelContext: modelContext)
            viewModel.loadBacklogs()
            viewModel.loadCategories()
            dailyFocusViewModel?.loadDailyTasks()
            expandedCategories.removeAll()
        } catch {
            viewModel.errorMessage = String(
                format: String(localized: "backlog.debug.clear.error", defaultValue: "Löschen fehlgeschlagen: %@"),
                error.localizedDescription
            )
        }
    }
    #endif
    
    // MARK: - Subviews
    
    /// Kategorisierte Ansicht mit Sections pro Kategorie
    private var categorizedTaskListView: some View {
        let grouped = viewModel.groupedTasks
        let sortedCategories = viewModel.categories.sorted()
        
        // #region agent log
        writeLog(["location": "BacklogView.swift:95", "message": "categorizedTaskListView rendering", "data": ["categoriesCount": sortedCategories.count, "groupedCount": grouped.count, "categories": sortedCategories.map { ["id": $0.id.uuidString, "type": $0.categoryType.rawValue, "name": $0.name, "tasksCount": grouped[$0.id]?.count ?? 0, "isUncategorized": $0.isUncategorized] }], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "post-fix", "hypothesisId": "C"])
        // #endregion
        
        return List {
            ForEach(sortedCategories, id: \.id) { category in
                let tasks = grouped[category.id] ?? []
                let isExpanded = expandedCategories.contains(category.id) || (!tasks.isEmpty && !category.isUncategorized)
                
                // Zeige alle Kategorien an (leere werden eingeklappt angezeigt)
                Section {
                    if isExpanded {
                        ForEach(tasks, id: \.id) { task in
                                TaskRowView(
                                    task: task,
                                    onToggle: nil,
                                    onDelete: {
                                        _Concurrency.Task {
                                            await viewModel.deleteTask(task)
                                        }
                                    },
                                    showBacklogBadge: false
                                )
                                .swipeActions(edge: .leading) {
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
                                .contextMenu {
                                    categoryContextMenu(for: task)
                                }
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
                    }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    /// Unkategorisierte Ansicht (flache Liste)
    private var uncategorizedTaskListView: some View {
        List {
            ForEach(viewModel.backlogTasks) { task in
                TaskRowView(
                    task: task,
                    onToggle: nil,
                    onDelete: {
                        _Concurrency.Task {
                            await viewModel.deleteTask(task)
                        }
                    },
                    showBacklogBadge: false
                )
                .swipeActions(edge: .leading) {
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
            }
            .onMove { source, destination in
                viewModel.moveTasks(from: source, to: destination)
            }
        }
        .listStyle(.insetGrouped)
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
