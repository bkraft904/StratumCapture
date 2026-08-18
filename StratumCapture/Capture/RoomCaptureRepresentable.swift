import SwiftUI
import RoomPlan

/// Bridges RoomPlan's UIKit `RoomCaptureView` into SwiftUI. The view owns
/// its own `RoomCaptureSession`; we just wire delegates to it and start it
/// running as soon as it's added to the hierarchy.
struct RoomCaptureRepresentable: UIViewRepresentable {
    let manager: RoomScanManager

    func makeUIView(context: Context) -> RoomCaptureView {
        let view = RoomCaptureView(frame: .zero)
        view.delegate = manager
        view.captureSession.delegate = manager
        manager.activeSession = view.captureSession
        view.captureSession.run(configuration: RoomCaptureSession.Configuration())
        return view
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        // No dynamic updates needed — start/stop is driven from CaptureScreen.
    }

    static func dismantleUIView(_ uiView: RoomCaptureView, coordinator: ()) {
        uiView.captureSession.stop()
    }
}
