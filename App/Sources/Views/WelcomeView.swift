//
//  WelcomeView.swift
//  Dawny
//
//  Welcome Screen – nur nach Installation angezeigt
//

import SwiftUI

struct WelcomeView: View {
    @State private var currentPage = 0
    var onDismiss: () -> Void
    
    private let pages: [WelcomePage] = [
        WelcomePage(
            icon: "sun.horizon.fill",
            iconColor: .orange,
            title: "Willkommen bei Dawny",
            body: "Deine To-do-Liste, die jeden Morgen mit dir aufwacht – frisch und ohne Altlasten."
        ),
        WelcomePage(
            icon: "tray.fill",
            iconColor: .blue,
            title: "Sammle alles im Backlog",
            body: "Wirf Aufgaben einfach rein – grob kategorisiert, ohne Deadline-Stress. Dein Backlog vergisst nichts."
        ),
        WelcomePage(
            icon: "sun.max.fill",
            iconColor: .orange,
            title: "Plane deinen Tag bewusst",
            body: "Jeden Morgen entscheidest du neu: Was ist heute wirklich wichtig? Schiebe genau diese Tasks nach \u{201E}Heute\u{201C}."
        ),
        WelcomePage(
            icon: "sparkles",
            iconColor: .purple,
            title: "Bei Tagesanbruch: Reset",
            body: "Was du nicht geschafft hast, wandert automatisch zurück ins Backlog. Kein schlechtes Gewissen – morgen ist ein neuer Tag."
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageView(page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            
            bottomSection
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Page Content
    
    private func pageView(_ page: WelcomePage) -> some View {
        VStack(spacing: 28) {
            Spacer()
            
            Image(systemName: page.icon)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(page.iconColor.gradient)
                .symbolEffect(.pulse, options: .repeating.speed(0.5))
            
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 36)
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomSection: some View {
        VStack(spacing: 20) {
            pageIndicator
            
            if currentPage == pages.count - 1 {
                Button(action: onDismiss) {
                    Text("Los geht's")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            } else {
                Button {
                    withAnimation {
                        currentPage += 1
                    }
                } label: {
                    Text("Weiter")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.orange : Color.secondary.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
            }
        }
    }
}

// MARK: - Model

private struct WelcomePage {
    let icon: String
    let iconColor: Color
    let title: String
    let body: String
}

#Preview {
    WelcomeView(onDismiss: {})
}
