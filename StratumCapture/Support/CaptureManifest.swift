import Foundation
import RoomPlan
import simd

/// A JSON snapshot of one scan: RoomPlan's real wall geometry, plus whatever
/// AI findings were generated for each wall's tagged photos. There's no
/// backend endpoint that consumes this yet — exporting it is the manual
/// stand-in for a future `/capture` upload, so a person can inspect or hand
/// off the raw data today.
struct CaptureManifest: Codable {
    struct Vector3Data: Codable {
        let x: Float
        let y: Float
        let z: Float

        init(_ v: simd_float3) {
            x = v.x
            y = v.y
            z = v.z
        }
    }

    /// Column-major, matching `simd_float4x4.columns.(0...3)` — each inner
    /// array is one column [x, y, z, w].
    struct Transform4x4Data: Codable {
        let columns: [[Float]]

        init(_ m: simd_float4x4) {
            columns = [
                [m.columns.0.x, m.columns.0.y, m.columns.0.z, m.columns.0.w],
                [m.columns.1.x, m.columns.1.y, m.columns.1.z, m.columns.1.w],
                [m.columns.2.x, m.columns.2.y, m.columns.2.z, m.columns.2.w],
                [m.columns.3.x, m.columns.3.y, m.columns.3.z, m.columns.3.w],
            ]
        }
    }

    struct FindingEntry: Codable {
        let category: String
        let label: String
        let description: String
        let evidence: String
        let confidence: String

        init(_ finding: AnalyzeAPI.Finding) {
            category = finding.category
            label = finding.label
            description = finding.description
            evidence = finding.evidence
            confidence = finding.confidence
        }
    }

    struct WallEntry: Codable {
        let id: UUID
        let label: String
        /// Wall width/height/thickness in meters, RoomPlan's native units.
        let dimensions: Vector3Data
        let transform: Transform4x4Data
        let photoCount: Int
        let imageType: String?
        let scopeNote: String?
        let summary: String?
        let findings: [FindingEntry]
        let caveats: String?
    }

    let sessionID: UUID
    let capturedAt: Date
    let generatedAt: Date
    let walls: [WallEntry]

    static func build(session: CaptureSession, analyses: [UUID: AnalyzeAPI.AnalysisResult]) -> CaptureManifest {
        let entries = session.walls.enumerated().map { index, wall -> WallEntry in
            let result = analyses[wall.identifier]
            let photoCount = session.taggedPhotos.filter { $0.wallIdentifier == wall.identifier }.count
            return WallEntry(
                id: wall.identifier,
                label: wall.label(index: index),
                dimensions: Vector3Data(wall.dimensions),
                transform: Transform4x4Data(wall.transform),
                photoCount: photoCount,
                imageType: result?.imageType,
                scopeNote: result?.scopeNote,
                summary: result?.summary,
                findings: (result?.findings ?? []).map(FindingEntry.init),
                caveats: result?.caveats
            )
        }
        return CaptureManifest(
            sessionID: session.id,
            capturedAt: session.capturedAt,
            generatedAt: Date(),
            walls: entries
        )
    }
}
