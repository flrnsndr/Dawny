//
//  CategoryHeaderView.swift
//  Dawny
//
//  Header-View für kollabierbare Kategorie-Sections
//

import SwiftUI

struct CategoryHeaderView: View {
    let category: Category
    let taskCount: Int
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        // Kein `Button`: sonst blockiert die Interaktion oft SwiftUI-`dropDestination` auf dem Header (Cross-Category-Drag).
        HStack {
            Image(systemName: category.iconName)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(category.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            if taskCount > 0 {
                Text("\(taskCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}

