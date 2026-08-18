import SwiftUI
import RoomPlan

/// Post-scan hub: lists every wall RoomPlan detected, lets you tag photos of
/// open stud bays to specific walls, run the AI analysis per wall, and
/// export the result (manifest JSON, or the raw USDZ model).
struct ReviewScreen: View {
    @ObservedObject var session: CaptureSession
    @StateObject private var viewModel = ReviewViewModel()

    @State private var pendingPhotoWall: (id: UUID, label: String)?
    @State private var showingCamera = false
    @State private var usdzExportURL: IdentifiableURL?
    @State private var usdzExportError: String?

    private var walls: [CapturedRoom.Surface] { session.walls }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(walls.count) wall\(walls.count == 1 ? "" : "s") scanned")
                        .font(.headline)
                    Text(session.capturedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                ForEach(Array(walls.enumerated()), id: \.element.identifier) { index, wall in
                    let label = wall.label(index: index)
                    WallRowView(
                        wall: wall,
                        label: label,
                        photos: session.taggedPhotos.filter { $0.wallIdentifier == wall.identifier },
                        result: viewModel.analyses[wall.identifier],
                        isAnalyzing: viewModel.analyzingWallIDs.contains(wall.identifier),
                        error: viewModel.errors[wall.identifier],
                        onAddPhoto: {
                            pendingPhotoWall = (wall.identifier, label)
                            showingCamera = true
                        },
                        onAnalyze: {
                            let images = session.taggedPhotos
                                .filter { $0.wallIdentifier == wall.identifier }
                                .map(\.image)
                            Task { await viewModel.analyze(wallID: wall.identifier, images: images) }
                        }
                    )
                }
            } header: {
                Text("Tag photos to walls")
            } footer: {
                Text("Take a close-up photo of an open stud bay for a wall, then Analyze — findings are pinned to that wall's real RoomPlan geometry, not an illustrative layout.")
            }

            Section {
                Button {
                    viewModel.exportManifest(session: session)
                } label: {
                    Label("Export capture manifest (JSON)", systemImage: "square.and.arrow.up")
                }

                Button {
                    exportUSDZ()
                } label: {
                    Label("Export 3D model (USDZ)", systemImage: "cube")
                }
            }
        }
        .navigationTitle("Review scan")
        .sheet(isPresented: $showingCamera) {
            CameraPicker { image in
                if let target = pendingPhotoWall {
                    session.taggedPhotos.append(
                        TaggedPhoto(image: image, wallIdentifier: target.id, wallLabel: target.label)
                    )
                }
            }
        }
        .sheet(item: $viewModel.exportURL) { item in
            ShareSheet(items: [item.url])
        }
        .sheet(item: $usdzExportURL) { item in
            ShareSheet(items: [item.url])
        }
        .alert("Couldn't export USDZ", isPresented: usdzErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(usdzExportError ?? "")
        }
    }

    private var usdzErrorBinding: Binding<Bool> {
        Binding(get: { usdzExportError != nil }, set: { if !$0 { usdzExportError = nil } })
    }

    private func exportUSDZ() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("stratum-capture-\(session.id.uuidString.prefix(8))")
            .appendingPathExtension("usdz")
        do {
            try session.capturedRoom.export(to: url, exportOptions: .parametric)
            usdzExportURL = IdentifiableURL(url: url)
        } catch {
            usdzExportError = error.localizedDescription
        }
    }
}
