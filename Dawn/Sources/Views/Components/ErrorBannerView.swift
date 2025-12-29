//
//  ErrorBannerView.swift
//  Dawn
//
//  Reusable Error Banner
//

import SwiftUI

struct ErrorBannerView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(2)
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding()
        .background(.red.gradient)
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview {
    ErrorBannerView(message: "Synchronisation fehlgeschlagen", onDismiss: {})
}
