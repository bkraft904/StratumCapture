import Foundation
import UIKit

/// Owns per-wall analysis state (in-flight requests, results, errors) and
/// the manifest export flow. Kept separate from `CaptureSession` — that
/// class just holds RoomPlan's raw data and tagged photos, this is UI/network
/// state layered on top.
@MainActor
final class ReviewViewModel: ObservableObject {
    @Published var analyses: [UUID: AnalyzeAPI.AnalysisResult] = [:]
    @Published var analyzingWallIDs: Set<UUID> = []
    @Published var errors: [UUID: String] = [:]
    @Published var exportURL: IdentifiableURL?

    func analyze(wallID: UUID, images: [UIImage]) async {
        guard !images.isEmpty else { return }
        analyzingWallIDs.insert(wallID)
        errors[wallID] = nil
        defer { analyzingWallIDs.remove(wallID) }

        do {
            analyses[wallID] = try await AnalyzeAPI.analyze(images: images)
        } catch {
            errors[wallID] = error.localizedDescription
        }
    }

    func exportManifest(session: CaptureSession) {
        let manifest = CaptureManifest.build(session: session, analyses: analyses)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(manifest) else { return }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("stratum-capture-\(session.id.uuidString.prefix(8))")
            .appendingPathExtension("json")
        do {
            try data.write(to: url)
            exportURL = IdentifiableURL(url: url)
        } catch {
            // Writing to the app's own temp directory practically never
            // fails; if it does, there's nothing actionable to show here.
        }
    }
}
