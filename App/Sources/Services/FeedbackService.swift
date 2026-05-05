// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  FeedbackService.swift
//  Dawny
//
//  Hilfsfunktionen für In-App-Feedback via E-Mail
//

import UIKit

enum FeedbackService {
    static let recipient = "info@dawnyapp.com"

    static func mailSubject(version: String, build: String) -> String {
        "Dawny Feedback – v\(version) (\(build))"
    }

    static func deviceInfoBody() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let systemVersion = UIDevice.current.systemVersion
        let model = UIDevice.current.model
        let locale = Locale.current.identifier
        let resetHour = AppSettings.shared.resetHour

        return """


——
Dawny \(version) (\(build)) · iOS \(systemVersion) · \(model)
Locale: \(locale) · Reset: \(String(format: "%02d:00", resetHour))
"""
    }

    static func mailtoFallbackURL(version: String, build: String) -> URL? {
        let subject = mailSubject(version: version, build: build)
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = deviceInfoBody()
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "mailto:\(recipient)?subject=\(subject)&body=\(body)")
    }
}
