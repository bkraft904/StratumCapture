import SwiftUI
import RoomPlan

struct CaptureScreen: View {
    let onFinish: (CaptureSession) -> Void

    @StateObject private var manager = RoomScanManager()

    var body: some View {
        ZStack(alignment: .bottom) {
            RoomCaptureRepresentable(manager: manager)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(manager.instructionText)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.6), in: Capsule())
                    .foregroundStyle(.white)

                Button {
                    manager.finishScanning()
                } label: {
                    if manager.isFinishing {
                        Label("Processing scan…", systemImage: "hourglass")
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Done scanning", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .controlSize(.large)
                .padding(.horizontal, 24)
                .disabled(manager.isFinishing)
            }
            .padding(.bottom, 32)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            manager.onFinish = { capturedRoom in
                let session = CaptureSession(capturedRoom: capturedRoom)
                onFinish(session)
            }
        }
    }
}
