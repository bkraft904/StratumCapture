import Foundation

/// Wraps a URL so it can drive `.sheet(item:)` for export/share flows.
struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}
