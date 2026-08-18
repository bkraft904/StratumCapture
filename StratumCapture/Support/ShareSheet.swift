import SwiftUI
import UIKit

/// Standard share sheet for handing an exported file (manifest JSON, USDZ
/// model) off to Files, AirDrop, Messages, etc.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
