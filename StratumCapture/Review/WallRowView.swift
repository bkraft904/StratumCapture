import SwiftUI
import RoomPlan

struct WallRowView: View {
    let wall: CapturedRoom.Surface
    let label: String
    let photos: [TaggedPhoto]
    let result: AnalyzeAPI.AnalysisResult?
    let isAnalyzing: Bool
    let error: String?
    let onAddPhoto: () -> Void
    let onAnalyze: () -> Void

    private var dimensionsText: String {
        // RoomPlan reports dimensions in meters: x = width, y = height.
        String(format: "%.1fm × %.1fm", wall.dimensions.x, wall.dimensions.y)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.subheadline.weight(.semibold))
                    Text(dimensionsText).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let result {
                    Label("\(result.findings.count)", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                } else if isAnalyzing {
                    ProgressView()
                }
            }

            if !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(photos) { photo in
                            Image(uiImage: photo.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }

            if let error {
                Text(error).font(.caption).foregroundStyle(.red)
            }

            if let result {
                Text(result.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            HStack(spacing: 12) {
                Button(action: onAddPhoto) {
                    Label("Add photo", systemImage: "camera.fill")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(.cyan)

                Button(action: onAnalyze) {
                    Label(result == nil ? "Analyze" : "Re-analyze", systemImage: "sparkles")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(.purple)
                .disabled(photos.isEmpty || isAnalyzing)
            }
        }
        .padding(.vertical, 6)
    }
}
