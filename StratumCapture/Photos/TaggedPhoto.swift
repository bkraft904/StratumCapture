import UIKit
import RoomPlan

/// A photo the user explicitly tied to one real, RoomPlan-detected wall —
/// this is what lets the backend place findings at a real position instead
/// of the web app's illustrative layout.
struct TaggedPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
    let wallIdentifier: UUID
    let wallLabel: String
    let takenAt = Date()
}

extension CapturedRoom.Surface {
    /// A short human-readable label for picking this wall in the UI —
    /// RoomPlan doesn't name walls, so this is just "Wall 1", "Wall 2", …
    /// ordered by position in the room's wall array.
    func label(index: Int) -> String {
        "Wall \(index + 1)"
    }
}
