// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  CategorySelectionMenu.swift
//  Dawny
//
//  Long-Press-Menü zur Kategorieauswahl
//

import SwiftUI

struct CategorySelectionMenu: View {
    let categories: [Category]
    let currentCategory: Category?
    let onSelect: (Category?) -> Void
    
    var body: some View {
        Menu {
            // Option: Keine Kategorie (nur wenn nicht bereits unkategorisiert)
            if currentCategory?.isUncategorized != true {
                Button {
                    onSelect(nil)
                } label: {
                    Label(
                        String(localized: "category.menu.uncategorized", defaultValue: "Uncategorized"),
                        systemImage: "tag"
                    )
                }
            }
            
            Divider()
            
            // Alle verfügbaren Kategorien
            ForEach(categories, id: \.id) { category in
                Button {
                    onSelect(category)
                } label: {
                    HStack {
                        Image(systemName: category.displayIconName)
                        Text(category.displayName)
                        if currentCategory?.id == category.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "tag.fill")
                .foregroundColor(.secondary)
        }
    }
}

