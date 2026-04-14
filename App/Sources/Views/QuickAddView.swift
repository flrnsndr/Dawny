//
//  QuickAddView.swift
//  Dawny
//
//  Quick Add Sheet für neue Tasks
//

import SwiftUI

struct QuickAddView: View {
    enum AddDestination: String, CaseIterable, Identifiable {
        case backlog
        case today

        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    
    let categories: [Category]
    let defaultCategoryID: UUID?
    let initialDestination: AddDestination
    let onRequestAddTestItems: (() -> Void)?
    let onRequestDeleteAll: (() -> Void)?
    let onSave: (String, String?, Category?, AddDestination) -> Void
    
    @State private var title = ""
    @State private var notes = ""
    @State private var selectedCategoryID: UUID?
    @State private var destination: AddDestination
    @FocusState private var isTitleFocused: Bool

    init(
        categories: [Category],
        defaultCategoryID: UUID?,
        initialDestination: AddDestination,
        onRequestAddTestItems: (() -> Void)? = nil,
        onRequestDeleteAll: (() -> Void)? = nil,
        onSave: @escaping (String, String?, Category?, AddDestination) -> Void
    ) {
        self.categories = categories
        self.defaultCategoryID = defaultCategoryID
        self.initialDestination = initialDestination
        self.onRequestAddTestItems = onRequestAddTestItems
        self.onRequestDeleteAll = onRequestDeleteAll
        self.onSave = onSave
        _destination = State(initialValue: initialDestination)
    }
    
    private var sortedCategories: [Category] {
        categories.sorted()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "quickadd.target.section", defaultValue: "Ziel")) {
                    Picker(String(localized: "quickadd.target.section", defaultValue: "Ziel"), selection: $destination) {
                        Text(String(localized: "quickadd.target.backlog", defaultValue: "Backlog"))
                            .tag(AddDestination.backlog)
                        Label(String(localized: "task.status.today", defaultValue: "Heute"), systemImage: "sun.max.fill")
                            .tag(AddDestination.today)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    TextField(String(localized: "quickadd.task.placeholder", defaultValue: "Task"), text: $title)
                        .focused($isTitleFocused)
                        .submitLabel(.done)
                        .onSubmit { saveTask() }
                }
                
                if !sortedCategories.isEmpty {
                    Section(String(localized: "quickadd.category.section", defaultValue: "Kategorie")) {
                        if destination == .backlog {
                            Picker(String(localized: "quickadd.category.section", defaultValue: "Kategorie"), selection: $selectedCategoryID) {
                                ForEach(sortedCategories, id: \.id) { category in
                                    Label(category.name, systemImage: category.iconName)
                                        .tag(Optional(category.id))
                                }
                            }
                        } else {
                            HStack(spacing: 8) {
                                if let quickCategory = quickCategory {
                                    Label(quickCategory.name, systemImage: quickCategory.iconName)
                                        .labelStyle(.titleAndIcon)
                                } else if let selectedCategory = sortedCategories.first(where: { $0.id == selectedCategoryID }) {
                                    Label(selectedCategory.name, systemImage: selectedCategory.iconName)
                                        .labelStyle(.titleAndIcon)
                                }
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(.secondary)
                                Label(String(localized: "task.status.today", defaultValue: "Heute"), systemImage: "sun.max.fill")
                                    .foregroundStyle(.orange)
                            }
                            .font(.footnote)
                            .accessibilityLabel(String(localized: "quickadd.target.today", defaultValue: "Dieser Task wird nach Heute verschoben"))
                        }
                    }
                }
                
                Section(String(localized: "quickadd.notes.section", defaultValue: "Notizen (optional)")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(String(localized: "quickadd.title", defaultValue: "Neuer Task"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let onRequestAddTestItems {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            onRequestAddTestItems()
                        } label: {
                            Image(systemName: "wand.and.stars")
                        }
                        .accessibilityLabel(String(localized: "quickadd.addtestitems", defaultValue: "Testelemente hinzufügen"))
                    }
                }

                if let onRequestDeleteAll {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(role: .destructive) {
                            onRequestDeleteAll()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel(String(localized: "quickadd.deleteall", defaultValue: "Alle Tasks löschen"))
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "quickadd.cancel", defaultValue: "Abbrechen")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "quickadd.add", defaultValue: "Hinzufügen")) {
                        saveTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                applyDefaultCategorySelection()
                DispatchQueue.main.async {
                    isTitleFocused = true
                }
            }
            .onChange(of: destination) { _, newValue in
                if newValue == .today, let quickCategory {
                    selectedCategoryID = quickCategory.id
                } else if selectedCategoryID == nil {
                    applyDefaultCategorySelection()
                }
            }
        }
    }

    private var quickCategory: Category? {
        sortedCategories.first { $0.categoryType == .quick }
    }

    private func applyDefaultCategorySelection() {
        guard !sortedCategories.isEmpty else { return }
        if destination == .today, let quickCategory {
            selectedCategoryID = quickCategory.id
            return
        }
        if let def = defaultCategoryID, sortedCategories.contains(where: { $0.id == def }) {
            selectedCategoryID = def
        } else {
            selectedCategoryID = sortedCategories.first?.id
        }
    }
    
    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else { return }
        
        let chosenCategory: Category? = {
            guard !sortedCategories.isEmpty else { return nil }
            let id = selectedCategoryID ?? sortedCategories.first?.id
            return sortedCategories.first { $0.id == id }
        }()
        
        onSave(trimmedTitle, trimmedNotes.isEmpty ? nil : trimmedNotes, chosenCategory, destination)
        dismiss()
    }
}

#Preview {
    QuickAddView(categories: [], defaultCategoryID: nil, initialDestination: .backlog) { title, notes, category, destination in
        print("Saved: \(title), \(notes ?? "no notes"), category: \(String(describing: category))")
    }
}
