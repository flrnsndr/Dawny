// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  AddCategoryRow.swift
//  Dawny
//
//  Ghost row that opens the category editor sheet on tap.
//

import SwiftUI

struct AddCategoryRow: View {
    let onTap: () -> Void

    private var placeholder: String {
        String(localized: "category.add.placeholder", defaultValue: "New category")
    }

    var body: some View {
        HStack {
            Image(systemName: "plus")
                .foregroundStyle(.secondary)
                .opacity(0.6)
                .frame(width: 20)

            Text(placeholder)
                .font(.headline)
                .foregroundStyle(.secondary)
                .opacity(0.6)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(localized: "category.add.accessibility", defaultValue: "Add new category")
        )
        .accessibilityAddTraits(.isButton)
    }
}
