// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

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

    @State private var expandedCategories: Set<UUID> = []
    @State private var focusedTaskID: UUID?
    @State private var isSortingCategories = false
    @State private var expandedCategoriesBeforeSort: Set<UUID> = []

    // MARK: - Category Editing State

    /// ID der Kategorie, die gerade per Inline-TextField umbenannt wird.
    @State private var editingCategoryID: UUID?
    /// Kategorie, für die das Aktionsmenü (Long-Press) offen ist.
    @State private var actionsCategory: Category?
    /// Kategorie, für die der Symbol-Picker geöffnet ist.
    @State private var iconPickerCategory: Category?
    /// Kategorie, die gerade gelöscht werden soll (Confirmation Dialog).
    @State private var pendingDeleteCategory: Category?

    var body: some View {
        NavigationStack {
            ZStack {
                if settings.showCategories {
                    if isSortingCategories {
                        sortModeView
                    } else {
                        ScrollViewReader { proxy in
                            categorizedTaskListView(scrollProxy: proxy)
                        }
                    }
                } else {
                    ScrollViewReader { proxy in
                        uncategorizedTaskListView(scrollProxy: proxy)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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
                    onDelete: { category in requestDelete(category) },
                    onReorder: { category in activateSortMode(startingWith: category) },
                    onToggleRecurring: { category in
                        _ = viewModel.toggleRecurring(category)
                    }
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
            .onAppear {
                viewModel.loadBacklogs()
                viewModel.loadCategories()
                if settings.showCategories {
                    viewModel.migrateUncategorizedTasksIfNeeded()
                    viewModel.loadCategories()
                }
                initializeExpandedCategories()
            }
            .onChange(of: settings.showCategories) { oldValue, newValue in
                if newValue {
                    // Wenn Kategorien aktiviert werden, migriere Tasks ohne Kategorie
                    viewModel.migrateUncategorizedTasksIfNeeded()
                    viewModel.loadCategories()
                    initializeExpandedCategories()
                }
            }
            .onChange(of: viewModel.taskCount) { oldCount, newCount in
                guard settings.showCategories else { return }
                // Re-init bei "leer" und ebenso wenn Tasks neu reinkommen
                // (z.B. nach Debug-Reset oder Hinzufügen von Test-Items aus den Settings).
                if newCount == 0 || (oldCount == 0 && newCount > 0) {
                    initializeExpandedCategories()
                }
            }
            .overlay(alignment: .top) {
                VStack(spacing: 8) {
                    if isSortingCategories {
                        HStack {
                            Text(
                                String(
                                    localized: "category.sort.title",
                                    defaultValue: "Arrange Categories"
                                )
                            )
                            .font(.headline)

                            Spacer()

                            Button(
                                String(localized: "common.done", defaultValue: "Done")
                            ) {
                                exitSortMode()
                            }
                            .fontWeight(.semibold)
                        }
                        .padding()
                        .background(.regularMaterial)
                    }

                    if let error = viewModel.errorMessage {
                        ErrorBannerView(message: error) {
                            viewModel.errorMessage = nil
                        }
                        .padding(.horizontal, 8)
                        .onAppear {
                            HapticFeedback.error()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Kategorisierte Ansicht mit Sections pro Kategorie
    private func categorizedTaskListView(scrollProxy: ScrollViewProxy) -> some View {
        let grouped = viewModel.groupedTasks
        let sortedCategories = viewModel.categories.sorted()
        let placeholder = String(localized: "quickentry.placeholder", defaultValue: "New task…")

        return List {
            ForEach(sortedCategories, id: \.id) { category in
                let tasks = grouped[category.id] ?? []
                let isExpanded = expandedCategories.contains(category.id)
                let isEditingThis = editingCategoryID == category.id

                // Alle Kategorien; leere sind standardmäßig aufgeklappt, sobald der Backlog leer ist
                Section {
                    if isExpanded {
                        ForEach(tasks, id: \.id) { task in
                            backlogCategorizedTaskRow(task: task)
                        }
                        .onMove { source, destination in
                            viewModel.moveTasksWithinCategory(
                                category: category,
                                from: source,
                                to: destination
                            )
                        }
                        backlogQuickEntryRow(
                            scrollProxy: scrollProxy,
                            scrollID: AnyHashable("qe-backlog-cat-\(category.id.uuidString)"),
                            placeholder: placeholder,
                            category: category
                        )
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
                AddCategoryRow { name, isRecurring in
                    if let created = viewModel.createCategory(name: name, isRecurring: isRecurring) {
                        expandedCategories.insert(created.id)
                    }
                }
            }
        }
        .listStyle(.plain)
        .listSectionSpacing(.compact)
        .environment(\.defaultMinListRowHeight, 36)
    }

    /// Sortiermodus: flache Liste aller Kategorien ohne Tasks, Quick-Entry oder Add-Row.
    private var sortModeView: some View {
        let grouped = viewModel.groupedTasks
        let sortedCategories = viewModel.categories.sorted()

        return List {
            ForEach(sortedCategories, id: \.id) { category in
                sortModeCategoryRow(
                    category: category,
                    taskCount: grouped[category.id]?.count ?? 0
                )
            }
            .onMove { source, destination in
                viewModel.reorderCategories(from: source, to: destination)
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active))
        .environment(\.defaultMinListRowHeight, 44)
    }

    @ViewBuilder
    private func sortModeCategoryRow(category: Category, taskCount: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: category.displayIconName)
                .foregroundColor(.secondary)
                .frame(width: 18)

            Text(category.displayName)
                .font(.headline)
                .foregroundColor(.primary)

            if category.isRecurring {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .accessibilityLabel(
                        String(
                            localized: "task.recurring.badge",
                            defaultValue: "Recurring"
                        )
                    )
            }

            Spacer()

            if taskCount > 0 {
                Text(taskCount, format: .number)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }

    @ViewBuilder
    private func backlogQuickEntryRow(
        scrollProxy: ScrollViewProxy,
        scrollID: AnyHashable,
        placeholder: String,
        category: Category
    ) -> some View {
        QuickEntryRow(
            placeholder: placeholder,
            categoryAccessibilityName: category.displayName,
            scrollID: scrollID,
            onSubmit: { title in
                if viewModel.addTask(title: title, category: category, placement: .bottomOfCategory) != nil {
                    expandedCategories.insert(category.id)
                }
            },
            onFocusChange: { focused in
                guard focused else { return }
                DispatchQueue.main.async {
                    withAnimation {
                        scrollProxy.scrollTo(scrollID, anchor: .bottom)
                    }
                }
            }
        )
        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
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
        let configured = header
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .listRowSeparator(.hidden)

        if isEditingName {
            configured
        } else {
            configured.dropDestination(for: BacklogTaskTransfer.self) { items, _ in
                return handleCategoryHeaderDrop(items, targetCategory: category)
            }
        }
    }
    
    /// Unkategorisierte Ansicht (flache Liste + Quick Entry)
    private func uncategorizedTaskListView(scrollProxy: ScrollViewProxy) -> some View {
        let placeholder = String(localized: "quickentry.placeholder", defaultValue: "New task…")
        let scrollID = AnyHashable("qe-backlog-uncategorized")

        return List {
            ForEach(viewModel.backlogTasks, id: \.id) { task in
                backlogUncategorizedRow(task: task)
            }
            .onMove { source, destination in
                viewModel.moveTasks(from: source, to: destination)
            }
            QuickEntryRow(
                placeholder: placeholder,
                categoryAccessibilityName: String(localized: "backlog.title", defaultValue: "Backlog"),
                scrollID: scrollID,
                onSubmit: { title in
                    _ = viewModel.addTask(title: title, category: nil, placement: .bottomOfCategory)
                },
                onFocusChange: { focused in
                    guard focused else { return }
                    DispatchQueue.main.async {
                        withAnimation {
                            scrollProxy.scrollTo(scrollID, anchor: .bottom)
                        }
                    }
                }
            )
            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
        }
        .listStyle(.plain)
        .listSectionSpacing(.compact)
        .environment(\.defaultMinListRowHeight, 36)
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
            showBacklogBadge: false,
            showRecurringTaskBadge: false,
            showsDisabledToggle: true,
            focusedTaskID: $focusedTaskID,
            onSaveTitle: { newTitle in
                _Concurrency.Task {
                    await viewModel.updateTask(task, title: newTitle, notes: task.notes)
                }
            }
        )
        .swipeActions(edge: .leading) {
            Button {
                HapticFeedback.medium()
                _Concurrency.Task {
                    await viewModel.moveTaskToDailyFocus(task)
                    await MainActor.run {
                        dailyFocusViewModel?.loadDailyTasks()
                    }
                }
            } label: {
                Label(String(localized: "backlog.swipe.today", defaultValue: "Today"), systemImage: "sun.max.fill")
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
            showBacklogBadge: false,
            showRecurringTaskBadge: false,
            showsDisabledToggle: true,
            focusedTaskID: $focusedTaskID,
            onSaveTitle: { newTitle in
                _Concurrency.Task {
                    await viewModel.updateTask(task, title: newTitle, notes: task.notes)
                }
            }
        )
        .contextMenu {
            categoryContextMenu(for: task)
        }
        .swipeActions(edge: .leading) {
            Button {
                HapticFeedback.medium()
                _Concurrency.Task {
                    await viewModel.moveTaskToDailyFocus(task)
                    await MainActor.run {
                        dailyFocusViewModel?.loadDailyTasks()
                    }
                }
            } label: {
                Label(String(localized: "backlog.swipe.today", defaultValue: "Today"), systemImage: "sun.max.fill")
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

    // MARK: - Helper Methods
    
    /// Initialisiert aufgeklappte Kategorien: Ohne Backlog-Tasks sind alle Standardkategorien
    /// aufgeklappt (Quick-Entry sichtbar). Sobald Tasks existieren, werden nur Kategorien
    /// mit mindestens einer Task automatisch geöffnet.
    private func initializeExpandedCategories() {
        guard settings.showCategories else { return }

        if viewModel.backlogTasks.isEmpty {
            expandedCategories = Set(viewModel.categories.sorted().map(\.id))
            return
        }

        let grouped = viewModel.groupedTasks
        for (categoryId, tasks) in grouped where !tasks.isEmpty {
            expandedCategories.insert(categoryId)
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
                    String(localized: "category.menu.uncategorized", defaultValue: "Uncategorized"),
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
    
    // MARK: - Category Editing Actions

    private func activateSortMode(startingWith _: Category) {
        guard !isSortingCategories else { return }
        actionsCategory = nil
        editingCategoryID = nil
        iconPickerCategory = nil
        focusedTaskID = nil
        expandedCategoriesBeforeSort = expandedCategories
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedCategories = []
            isSortingCategories = true
        }
        HapticFeedback.light()
    }

    private func exitSortMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isSortingCategories = false
            expandedCategories = expandedCategoriesBeforeSort
            expandedCategoriesBeforeSort = []
        }
        HapticFeedback.light()
    }

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
    let onReorder: (Category) -> Void
    let onToggleRecurring: (Category) -> Void

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
                        defaultValue: "Edit"
                    )
                ) {
                    onEdit(category)
                }
            }
            Button(
                String(
                    localized: "category.action.reorder",
                    defaultValue: "Move"
                )
            ) {
                onReorder(category)
            }
            if category.canToggleRecurring {
                Button {
                    onToggleRecurring(category)
                } label: {
                    if category.isRecurring {
                        Text(
                            String(
                                localized: "category.action.unmakeRecurring",
                                defaultValue: "Remove recurring"
                            )
                        )
                    } else {
                        Text(
                            String(
                                localized: "category.action.makeRecurring",
                                defaultValue: "Mark as recurring"
                            )
                        )
                    }
                }
            }
            if category.canDelete {
                Button(
                    String(
                        localized: "category.action.delete",
                        defaultValue: "Delete"
                    ),
                    role: .destructive
                ) {
                    onDelete(category)
                }
            }
            Button(
                String(localized: "quickadd.cancel", defaultValue: "Cancel"),
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
                        defaultValue: "Delete Tasks Too"
                    ),
                    role: .destructive
                ) {
                    onDelete(.deleteTasks)
                }
                Button(
                    String(
                        localized: "category.delete.moveTasks",
                        defaultValue: "Move Tasks to Uncategorized"
                    )
                ) {
                    onDelete(.moveToUncategorized)
                }
            } else {
                Button(
                    String(
                        localized: "category.delete.confirm",
                        defaultValue: "Delete"
                    ),
                    role: .destructive
                ) {
                    // Bei 0 Tasks ist die Strategie egal – wir nehmen die sicherere.
                    onDelete(.moveToUncategorized)
                }
            }

            Button(
                String(localized: "quickadd.cancel", defaultValue: "Cancel"),
                role: .cancel
            ) {
                pendingCategory = nil
            }
        } message: { category in
            let count = category.tasks.count
            if count > 0 {
                let format = String(
                    localized: "category.delete.message",
                    defaultValue: "This category contains %lld task(s). What should happen to them?"
                )
                Text(String(format: format, locale: .current, count))
            } else {
                Text(
                    String(
                        localized: "category.delete.messageEmpty",
                        defaultValue: "This category contains no tasks."
                    )
                )
            }
        }
    }

    private var titleText: String {
        if let name = pendingCategory?.displayName {
            let format = String(
                localized: "category.delete.title",
                defaultValue: "Delete category \u{201C}%@\u{201D}?"
            )
            return String(format: format, name)
        }
        return String(
            localized: "category.delete.titleFallback",
            defaultValue: "Delete category?"
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
