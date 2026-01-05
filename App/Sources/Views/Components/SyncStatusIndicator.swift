//
//  SyncStatusIndicator.swift
//  Dawny
//
//  Sync Status Indicator Component
//

import SwiftUI

enum SyncStatus {
    case idle
    case syncing
    case success
    case error
    
    var icon: String {
        switch self {
        case .idle:
            return "arrow.triangle.2.circlepath"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .idle:
            return .gray
        case .syncing:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        }
    }
}

struct SyncStatusIndicator: View {
    let status: SyncStatus
    let lastSyncDate: Date?
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.icon)
                .foregroundStyle(status.color)
                .rotationEffect(.degrees(isAnimating && status == .syncing ? 360 : 0))
                .animation(
                    status == .syncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                    value: isAnimating
                )
            
            if let lastSync = lastSyncDate, status != .syncing {
                Text(timeAgo(from: lastSync))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if status == .syncing {
                Text(String(localized: "sync.status.progress", defaultValue: "Synchronisiere..."))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            if status == .syncing {
                isAnimating = true
            }
        }
        .onChange(of: status) { oldValue, newValue in
            isAnimating = newValue == .syncing
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return String(localized: "sync.status.just.now", defaultValue: "Gerade eben")
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return String(localized: "sync.status.minutes.ago", defaultValue: "vor %d Min").replacingOccurrences(of: "%d", with: "\(minutes)")
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return String(localized: "sync.status.hours.ago", defaultValue: "vor %d Std").replacingOccurrences(of: "%d", with: "\(hours)")
        } else {
            let days = Int(interval / 86400)
            if days == 1 {
                return String(localized: "sync.status.days.ago", defaultValue: "vor %d Tag").replacingOccurrences(of: "%d", with: "\(days)")
            } else {
                return String(localized: "sync.status.days.ago.plural", defaultValue: "vor %d Tagen").replacingOccurrences(of: "%d", with: "\(days)")
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SyncStatusIndicator(status: .idle, lastSyncDate: Date().addingTimeInterval(-300))
        SyncStatusIndicator(status: .syncing, lastSyncDate: nil)
        SyncStatusIndicator(status: .success, lastSyncDate: Date().addingTimeInterval(-60))
        SyncStatusIndicator(status: .error, lastSyncDate: Date().addingTimeInterval(-3600))
    }
    .padding()
}
