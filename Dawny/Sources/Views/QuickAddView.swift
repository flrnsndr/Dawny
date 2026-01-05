//
//  QuickAddView.swift
//  Dawny
//
//  Quick Add Sheet für neue Tasks
//

import SwiftUI

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (String, String?) -> Void
    
    @State private var title = ""
    @State private var notes = ""
    @FocusState private var isTitleFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task", text: $title, axis: .vertical)
                        .focused($isTitleFocused)
                        .lineLimit(1...3)
                }
                
                Section("Notizen (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Neuer Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        saveTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isTitleFocused = true
            }
        }
    }
    
    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else { return }
        
        onSave(trimmedTitle, trimmedNotes.isEmpty ? nil : trimmedNotes)
        dismiss()
    }
}

#Preview {
    QuickAddView { title, notes in
        print("Saved: \(title), \(notes ?? "no notes")")
    }
}
