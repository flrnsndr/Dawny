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

    // MARK: - Category Editing State

    /// ID der Kategorie, die gerade per Inline-TextField umbenannt wird.
    @State private var editingCategoryID: UUID?
    /// Kategorie, für die das Aktionsmenü (Long-Press) offen ist.
    @State private var actionsCategory: Category?
    /// Kategorie, für die der Symbol-Picker geöffnet ist.
    @State private var iconPickerCategory: Category?
    /// Kategorie, die gerade gelöscht werden soll (Confirmation Dialog).
    @State private var pendingDeleteCategory: Category?
    
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel(String(localized: "settings.title", defaultValue: "Einstellungen"))
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
                            if let newTask = viewModel.addTask(title: title, notes: notes, category: category),
                               let categoryId = newTask.category?.id {
                                expandedCategories.insert(categoryId)
                            }
                        case .today:
                            let forcedCategory = quickCategory ?? category
                            if let newTask = viewModel.addTask(title: title, notes: notes, category: forcedCategory) {
                                if let categoryId = newTask.category?.id {
                                    expandedCategories.insert(categoryId)
                                }
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
            .sheet(item: $iconPickerCategory) { category in
                CategorySymbolPicker(currentSymbol: category.displayIconName) { newSymbol in
                    if viewModel.updateCategoryIcon(category, to: newSymbol) {
                        HapticFeedback.success()
                    }
                }
            }
            .modifier(
                CategoryActionMenu(
                    actionsCategory: $actionsCategory,
                    onEdit: { category in beginRenaming(category) },
                    onDelete: { category in requestDelete(category) }
                )
            )
            .modifier(
                CategoryDeleteConfirmation(
                    pendingCategory: $pendingDeleteCategory,
                    onDelete: { strategy in
                        guard let target = pendingDeleteCategory else { return }
                        performDelete(target, strategy: strategy)
                    }
                )
            )
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
                let isExpanded = expandedCategories.contains(category.id)
                let isEditingThis = editingCategoryID == category.id

                // Zeige alle Kategorien an (leere werden eingeklappt angezeigt)
                Section {
                    if isExpanded {
                        ForEach(tasks, id: \.id) { task in
                            backlogCategorizedTaskRow(task: task)
                        }
                    }
                    } header: {
                        categoryHeader(
                            for: category,
                            taskCount: tasks.count,
                            isExpanded: isExpanded,
                            isEditingName: isEditingThis
                        )
                    }
            }

            Section {
                AddCategoryRow { name in
                    if let created = viewModel.createCategory(name: name) {
                        expandedCategories.insert(created.id)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func categoryHeader(
        for category: Category,
        taskCount: Int,
        isExpanded: Bool,
        isEditingName: Bool
    ) -> some View {
        let header = CategoryHeaderView(
            category: category,
            taskCount: taskCount,
            isExpanded: isExpanded,
            isEditingName: isEditingName,
            isIconPickerOpen: isEditingName && iconPickerCategory?.id == category.id,
            onToggle: { toggleCategory(category.id) },
            onLongPress: { actionsCategory = category },
            onCommitRename: { newName in commitRename(category, to: newName) },
            onCancelRename: { editingCategoryID = nil },
            onIconTap: { iconPickerCategory = category }
        )

        // Drop-Target nur deaktivieren, wenn diese Zeile gerade editiert wird –
        // damit das TextField den Tap exklusiv bekommt und keine Tasks
        // versehentlich auf den Header gezogen werden.
        if isEditingName {
            header
        } else {
            header.dropDestination(for: BacklogTaskTransfer.self) { items, _ in
                return handleCategoryHeaderDrop(items, targetCategory: category)
            }
        }
    }
    
    /// Unkategorisierte Ansicht (flache Liste)
    private var uncategorizedTaskListView: some View {
        List {
            ForEach(viewModel.backlogTasks, id: \.id) { task in
                backlogUncategorizedRow(task: task)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    @ViewBuilder
    private func backlogUncategorizedRow(task: Task) -> some View {
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
    
    @ViewBuilder
    private func backlogCategorizedTaskRow(task: Task) -> some View {
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
        .contextMenu {
            categoryContextMenu(for: task)
        }
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
        .draggable(BacklogTaskTransfer(taskID: task.id))
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
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedCategories.contains(categoryId) {
                expandedCategories.remove(categoryId)
            } else {
                expandedCategories.insert(categoryId)
            }
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
                    Image(systemName: category.displayIconName)
                    Text(category.displayName)
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

    // MARK: - Category Editing Actions

    private func beginRenaming(_ category: Category) {
        guard category.canRename else { return }
        // Kategorie ausklappen, damit Tastatur das Feld nicht verdeckt
        // und der visuelle Kontext klar ist.
        if !expandedCategories.contains(category.id) {
            withAnimation(.easeInOut(duration: 0.2)) {
                _ = expandedCategories.insert(category.id)
            }
        }
        editingCategoryID = category.id
    }

    private func commitRename(_ category: Category, to newName: String) {
        let success = viewModel.renameCategory(category, to: newName)
        editingCategoryID = nil
        if success {
            HapticFeedback.success()
        } else {
            HapticFeedback.error()
        }
    }

    private func requestDelete(_ category: Category) {
        guard category.canDelete else { return }
        // Falls die Zeile gerade editiert wird, Edit beenden, bevor der Dialog kommt.
        if editingCategoryID == category.id {
            editingCategoryID = nil
        }
        HapticFeedback.warning()
        pendingDeleteCategory = category
    }

    private func performDelete(_ category: Category, strategy: CategoryDeleteStrategy) {
        let deletedID = category.id
        if viewModel.deleteCategory(category, strategy: strategy) {
            // Aufräumen: tote IDs aus dem Expanded-Set entfernen.
            expandedCategories.remove(deletedID)
            HapticFeedback.success()
        }
        pendingDeleteCategory = nil
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

// MARK: - Category Action Menu

/// Zeigt nach Long-Press auf den Kategorie-Header ein iOS-typisches
/// Bottom-Sheet-Aktionsmenü mit "Bearbeiten" und (optional) "Löschen".
///
/// "Bearbeiten" startet den Inline-Edit-Modus: der Cursor springt direkt
/// ins Namensfeld (Tastatur erscheint sofort) und der User kann zusätzlich
/// das Icon antippen, um den Symbol-Picker zu öffnen. Symbol- und Namens-
/// Bearbeitung sind also bewusst zu einem einzigen Edit-Flow zusammengefasst.
///
/// Wir verwenden bewusst `.confirmationDialog` statt `.contextMenu`:
/// `.contextMenu` ist auf List-Section-Headern in iOS 17+ unzuverlässig
/// (Gesture-Konflikte mit Tap und Drop). Der Confirmation-Dialog ist in
/// allen Kontexten stabil und fühlt sich nativ an.
private struct CategoryActionMenu: ViewModifier {
    @Binding var actionsCategory: Category?
    let onEdit: (Category) -> Void
    let onDelete: (Category) -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            titleText,
            isPresented: isPresentedBinding,
            titleVisibility: .visible,
            presenting: actionsCategory
        ) { category in
            if category.canRename || category.canChangeIcon {
                Button(
                    String(
                        localized: "category.action.edit",
                        defaultValue: "Bearbeiten"
                    )
                ) {
                    onEdit(category)
                }
            }
            if category.canDelete {
                Button(
                    String(
                        localized: "category.action.delete",
                        defaultValue: "Löschen"
                    ),
                    role: .destructive
                ) {
                    onDelete(category)
                }
            }
            Button(
                String(localized: "quickadd.cancel", defaultValue: "Abbrechen"),
                role: .cancel
            ) {
                actionsCategory = nil
            }
        }
    }

    private var titleText: String {
        actionsCategory?.displayName ?? ""
    }

    private var isPresentedBinding: Binding<Bool> {
        Binding(
            get: { actionsCategory != nil },
            set: { newValue in
                if !newValue { actionsCategory = nil }
            }
        )
    }
}

// MARK: - Category Delete Confirmation

/// Zeigt einen kontextsensitiven Confirmation Dialog beim Löschen einer Kategorie:
/// - 0 Tasks → einfacher "Löschen / Abbrechen"-Dialog.
/// - >0 Tasks → User wählt zwischen "Tasks ebenfalls löschen" oder
///   "Tasks nach Unkategorisiert verschieben".
private struct CategoryDeleteConfirmation: ViewModifier {
    @Binding var pendingCategory: Category?
    let onDelete: (CategoryDeleteStrategy) -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            titleText,
            isPresented: isPresentedBinding,
            titleVisibility: .visible,
            presenting: pendingCategory
        ) { category in
            let count = category.tasks.count
            if count > 0 {
                Button(
                    String(
                        localized: "category.delete.deleteTasks",
                        defaultValue: "Tasks ebenfalls löschen"
                    ),
                    role: .destructive
                ) {
                    onDelete(.deleteTasks)
                }
                Button(
                    String(
                        localized: "category.delete.moveTasks",
                        defaultValue: "Tasks nach Unkategorisiert verschieben"
                    )
                ) {
                    onDelete(.moveToUncategorized)
                }
            } else {
                Button(
                    String(
                        localized: "category.delete.confirm",
                        defaultValue: "Löschen"
                    ),
                    role: .destructive
                ) {
                    // Bei 0 Tasks ist die Strategie egal – wir nehmen die sicherere.
                    onDelete(.moveToUncategorized)
                }
            }

            Button(
                String(localized: "quickadd.cancel", defaultValue: "Abbrechen"),
                role: .cancel
            ) {
                pendingCategory = nil
            }
        } message: { category in
            let count = category.tasks.count
            if count > 0 {
                Text(
                    String(
                        localized: "category.delete.message",
                        defaultValue: "Diese Kategorie enthält %d Aufgabe(n). Was soll mit ihnen passieren?"
                    )
                    .replacingOccurrences(of: "%d", with: "\(count)")
                )
            } else {
                Text(
                    String(
                        localized: "category.delete.messageEmpty",
                        defaultValue: "Diese Kategorie enthält keine Aufgaben."
                    )
                )
            }
        }
    }

    private var titleText: String {
        if let name = pendingCategory?.displayName {
            return String(
                localized: "category.delete.title",
                defaultValue: "Kategorie %@ löschen?"
            )
            .replacingOccurrences(of: "%@", with: "„\(name)\u{201C}")
        }
        return String(
            localized: "category.delete.titleFallback",
            defaultValue: "Kategorie löschen?"
        )
    }

    private var isPresentedBinding: Binding<Bool> {
        Binding(
            get: { pendingCategory != nil },
            set: { newValue in
                if !newValue { pendingCategory = nil }
            }
        )
    }
}
