import SwiftUI
import RoomPlan

struct ContentView: View {
    @State private var path: [Route] = []

    enum Route: Hashable {
        case capture
        case review(sessionID: UUID)
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "scanner")
                    .font(.system(size: 48))
                    .foregroundStyle(.cyan)

                Text("Stratum Capture")
                    .font(.system(.largeTitle, design: .rounded, weight: .semibold))

                Text("Scan a room's real geometry with RoomPlan, then tag photos of open stud bays to specific walls before you upload.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                if RoomCaptureSession.isSupported {
                    Button {
                        path.append(.capture)
                    } label: {
                        Label("Start a scan", systemImage: "arkit")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .controlSize(.large)
                    .padding(.horizontal, 32)
                } else {
                    Label("This device has no LiDAR sensor — RoomPlan requires an iPhone 12 Pro/Pro Max or later Pro model, or an iPad Pro (2020+).", systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 32)
                        .multilineTextAlignment(.leading)
                }

                Spacer().frame(height: 40)
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .capture:
                    CaptureScreen { session in
                        // Replace the capture screen with review once a scan finishes.
                        path.removeLast()
                        path.append(.review(sessionID: session.id))
                        CaptureStore.shared.save(session)
                    }
                case .review(let sessionID):
                    if let session = CaptureStore.shared.session(for: sessionID) {
                        ReviewScreen(session: session)
                    } else {
                        Text("Scan not found.")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
