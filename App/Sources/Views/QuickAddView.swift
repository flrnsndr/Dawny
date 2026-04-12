//
//  QuickAddView.swift
//  Dawny
//
//  Quick Add Sheet für neue Tasks
//

import SwiftUI

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    
    let categories: [Category]
    let defaultCategoryID: UUID?
    let onSave: (String, String?, Category?) -> Void
    
    @State private var title = ""
    @State private var notes = ""
    @State private var selectedCategoryID: UUID?
    @FocusState private var isTitleFocused: Bool
    
    private var sortedCategories: [Category] {
        categories.sorted()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "quickadd.task.placeholder", defaultValue: "Task"), text: $title)
                        .focused($isTitleFocused)
                        .submitLabel(.done)
                        .onSubmit { saveTask() }
                }
                
                if !sortedCategories.isEmpty {
                    Section(String(localized: "quickadd.category.section", defaultValue: "Kategorie")) {
                        Picker(String(localized: "quickadd.category.section", defaultValue: "Kategorie"), selection: $selectedCategoryID) {
                            ForEach(sortedCategories, id: \.id) { category in
                                Label(category.name, systemImage: category.iconName)
                                    .tag(Optional(category.id))
                            }
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
                if selectedCategoryID == nil, !sortedCategories.isEmpty {
                    if let def = defaultCategoryID, sortedCategories.contains(where: { $0.id == def }) {
                        selectedCategoryID = def
                    } else {
                        selectedCategoryID = sortedCategories.first?.id
                    }
                }
                DispatchQueue.main.async {
                    isTitleFocused = true
                }
            }
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
        
        onSave(trimmedTitle, trimmedNotes.isEmpty ? nil : trimmedNotes, chosenCategory)
        dismiss()
    }
}

#Preview {
    QuickAddView(categories: [], defaultCategoryID: nil) { title, notes, category in
        print("Saved: \(title), \(notes ?? "no notes"), category: \(String(describing: category))")
    }
}
