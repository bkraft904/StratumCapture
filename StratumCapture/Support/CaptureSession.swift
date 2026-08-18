import Foundation
import RoomPlan

/// One completed RoomPlan scan, plus whatever photos the user tags to its
/// walls afterward. Held in memory only — `CaptureStore` is not persistence,
/// just a way to pass a non-trivially-Hashable `CapturedRoom` across
/// NavigationStack destinations by UUID instead of by value.
final class CaptureSession: ObservableObject, Identifiable {
    let id = UUID()
    let capturedRoom: CapturedRoom
    let capturedAt = Date()

    @Published var taggedPhotos: [TaggedPhoto] = []

    init(capturedRoom: CapturedRoom) {
        self.capturedRoom = capturedRoom
    }

    var walls: [CapturedRoom.Surface] {
        capturedRoom.walls
    }
}

@MainActor
final class CaptureStore {
    static let shared = CaptureStore()
    private var sessions: [UUID: CaptureSession] = [:]

    private init() {}

    func save(_ session: CaptureSession) {
        sessions[session.id] = session
    }

    func session(for id: UUID) -> CaptureSession? {
        sessions[id]
    }
}
