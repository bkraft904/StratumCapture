import Foundation
import RoomPlan

/// Drives one RoomCaptureView's session: surfaces live coaching instructions
/// to the UI, and hands back the final CapturedRoom once the framework
/// finishes post-processing.
final class RoomScanManager: ObservableObject, RoomCaptureSessionDelegate, RoomCaptureViewDelegate {
    @Published var instructionText: String = "Point the camera at a wall to begin."
    @Published var isFinishing: Bool = false

    var onFinish: ((CapturedRoom) -> Void)?

    /// Set by `RoomCaptureRepresentable` once the underlying view exists, so
    /// SwiftUI's "Done" button has something to call `stop()` on.
    weak var activeSession: RoomCaptureSession?

    func finishScanning() {
        isFinishing = true
        activeSession?.stop()
    }

    // MARK: RoomCaptureSessionDelegate

    func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {
        DispatchQueue.main.async {
            self.instructionText = Self.text(for: instruction)
        }
    }

    // MARK: RoomCaptureViewDelegate

    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: (any Error)?) -> Bool {
        // Let the framework's built-in post-processing run and hand us the
        // final, cleaned-up CapturedRoom via captureView(didPresent:error:).
        true
    }

    func captureView(didPresent processedResult: CapturedRoom, error: (any Error)?) {
        DispatchQueue.main.async {
            self.isFinishing = false
            self.onFinish?(processedResult)
        }
    }

    private static func text(for instruction: RoomCaptureSession.Instruction) -> String {
        switch instruction {
        case .normal:
            return "Keep moving — scanning normally."
        case .moveCloseToWall:
            return "Move closer to the wall."
        case .moveAwayFromWall:
            return "Move back from the wall a bit."
        case .turnOnLight:
            return "This room is too dark — turn on a light."
        case .slowDown:
            return "Slow down."
        case .lowTexture:
            return "Can't find enough detail here — try a different angle."
        @unknown default:
            return "Scanning…"
        }
    }
}
