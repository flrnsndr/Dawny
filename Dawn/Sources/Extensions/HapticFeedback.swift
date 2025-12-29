//
//  HapticFeedback.swift
//  Dawn
//
//  Haptic Feedback Helper
//

import UIKit

/// Helper für haptisches Feedback
enum HapticFeedback {
    /// Erfolg (z.B. Task completed)
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warnung (z.B. Fehler beim Sync)
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Fehler (z.B. Permission denied)
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Leichtes Impact (z.B. Button tap)
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Mittleres Impact (z.B. Swipe action)
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Starkes Impact (z.B. Delete)
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Selection Change (z.B. Toggle)
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
