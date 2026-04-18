//
//  CategorySymbolPicker.swift
//  Dawny
//
//  Sheet zum Auswählen eines SF-Symbols für eine Kategorie.
//  Kuratiertes Grid + Search.
//

import SwiftUI

struct CategorySymbolPicker: View {
    @Environment(\.dismiss) private var dismiss

    /// Aktuell aktives Symbol (für Hervorhebung im Grid).
    let currentSymbol: String

    /// Wird aufgerufen, sobald der User ein Symbol auswählt.
    let onSelect: (String) -> Void

    @State private var searchText: String = ""

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 6
    )

    private var filteredGroups: [SymbolGroup] {
        let query = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !query.isEmpty else {
            return SymbolGroup.curatedGroups
        }
        return SymbolGroup.curatedGroups.compactMap { group in
            let matches = group.symbols.filter { symbol in
                symbol.lowercased().contains(query)
                    || symbol.replacingOccurrences(of: ".", with: " ").lowercased().contains(query)
            }
            return matches.isEmpty ? nil : SymbolGroup(title: group.title, symbols: matches)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    if filteredGroups.isEmpty {
                        ContentUnavailableView(
                            String(
                                localized: "category.symbolPicker.empty.title",
                                defaultValue: "Keine Symbole gefunden"
                            ),
                            systemImage: "magnifyingglass",
                            description: Text(
                                String(
                                    localized: "category.symbolPicker.empty.message",
                                    defaultValue: "Versuche einen anderen Suchbegriff."
                                )
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        ForEach(filteredGroups) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 16)

                                LazyVGrid(columns: columns, spacing: 8) {
                                    ForEach(group.symbols, id: \.self) { symbol in
                                        symbolButton(symbol)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .navigationTitle(
                String(
                    localized: "category.symbolPicker.title",
                    defaultValue: "Symbol wählen"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text(
                    String(
                        localized: "category.symbolPicker.search",
                        defaultValue: "Suchen"
                    )
                )
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "quickadd.cancel", defaultValue: "Abbrechen")) {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func symbolButton(_ symbol: String) -> some View {
        let isSelected = symbol == currentSymbol
        Button {
            HapticFeedback.selection()
            onSelect(symbol)
            dismiss()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .frame(width: 44, height: 44)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.accentColor : Color.clear,
                            lineWidth: 2
                        )
                )
                .accessibilityLabel(symbol)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Symbol Catalog

private struct SymbolGroup: Identifiable {
    let title: String
    let symbols: [String]

    var id: String { title }

    /// Kuratierter Katalog. Reduziert auf Symbole, die in iOS 17+ stabil
    /// existieren und visuell zu einer Backlog-Kategorie passen.
    static let curatedGroups: [SymbolGroup] = [
        SymbolGroup(
            title: String(
                localized: "category.symbolPicker.section.suggested",
                defaultValue: "Empfohlen"
            ),
            symbols: [
                "bolt.fill", "calendar", "calendar.badge.clock",
                "calendar.badge.exclamationmark", "infinity", "tag",
                "list.bullet", "tray", "star.fill"
            ]
        ),
        SymbolGroup(
            title: String(
                localized: "category.symbolPicker.section.work",
                defaultValue: "Arbeit"
            ),
            symbols: [
                "briefcase.fill", "laptopcomputer", "envelope.fill",
                "doc.fill", "doc.text.fill", "folder.fill",
                "checklist", "chart.bar.fill", "chart.line.uptrend.xyaxis",
                "person.2.fill", "phone.fill", "video.fill"
            ]
        ),
        SymbolGroup(
            title: String(
                localized: "category.symbolPicker.section.personal",
                defaultValue: "Privat"
            ),
            symbols: [
                "house.fill", "heart.fill", "person.fill",
                "figure.walk", "figure.run", "bed.double.fill",
                "fork.knife", "cart.fill", "creditcard.fill",
                "gift.fill", "birthday.cake.fill"
            ]
        ),
        SymbolGroup(
            title: String(
                localized: "category.symbolPicker.section.hobby",
                defaultValue: "Hobby"
            ),
            symbols: [
                "book.fill", "paintbrush.fill", "music.note",
                "gamecontroller.fill", "headphones", "camera.fill",
                "guitars.fill", "film.fill", "leaf.fill",
                "pawprint.fill"
            ]
        ),
        SymbolGroup(
            title: String(
                localized: "category.symbolPicker.section.travel",
                defaultValue: "Reise & Outdoor"
            ),
            symbols: [
                "airplane", "car.fill", "tram.fill",
                "bicycle", "map.fill", "globe.europe.africa.fill",
                "mountain.2.fill", "sun.max.fill", "moon.fill",
                "cloud.fill"
            ]
        ),
        SymbolGroup(
            title: String(
                localized: "category.symbolPicker.section.symbols",
                defaultValue: "Symbole"
            ),
            symbols: [
                "flag.fill", "bookmark.fill", "pin.fill",
                "lightbulb.fill", "sparkles", "flame.fill",
                "drop.fill", "wand.and.stars", "circle.fill",
                "square.fill", "triangle.fill", "hexagon.fill",
                "exclamationmark.circle.fill", "questionmark.circle.fill"
            ]
        )
    ]
}

#Preview {
    CategorySymbolPicker(currentSymbol: "calendar") { _ in }
}
