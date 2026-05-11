// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  MailComposeView.swift
//  Dawny
//
//  SwiftUI-Wrapper für MFMailComposeViewController
//

import SwiftUI
import MessageUI

struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    var screenshotAttachment: UIImage? = nil
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        if let screenshot = screenshotAttachment,
           let data = screenshot.pngData() {
            vc.addAttachmentData(data, mimeType: "image/png", fileName: "screenshot.png")
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isPresented: Bool

        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            isPresented = false
        }
    }
}
