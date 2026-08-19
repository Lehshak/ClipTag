//
//  FramesView.swift
//  ClipTag
//
//  Created by Lehshak Teelockchand on 2026-08-17.
//

import SwiftUI

struct FramesView: View {
    let model: AnalysisViewModel
    @State private var selectedFrame: Keyframe?

    var body: some View {
        NavigationStack {
            Group {
                if let result = model.result {
                    grid(for: result)
                } else {
                    ContentUnavailableView(
                        "No Frames Yet",
                        systemImage: "square.grid.2x2",
                        description: Text("Analyze a clip and every sampled frame shows up here.")
                    )
                }
            }
            .navigationTitle("Frames")
            .sheet(item: $selectedFrame) { frame in
                FrameDetailView(frame: frame, isThumbnail: frame.id == model.result?.bestThumbnail?.id)
            }
        }
    }

    private func grid(for result: AnalysisResult) -> some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 104), spacing: 10)],
                spacing: 10
            ) {
                ForEach(result.keyframes) { frame in
                    Button {
                        selectedFrame = frame
                    } label: {
                        FrameCell(
                            frame: frame,
                            isThumbnail: frame.id == result.bestThumbnail?.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

private struct FrameCell: View {
    let frame: Keyframe
    let isThumbnail: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack(alignment: .topTrailing) {
                Image(decorative: frame.image, scale: 1, orientation: .up)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(minWidth: 0)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if isThumbnail {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .padding(5)
                        .background(.thinMaterial, in: Circle())
                        .padding(5)
                }
            }

            Text("\(frame.time, format: .number.precision(.fractionLength(1)))s")
                .font(.caption2.weight(.medium))
                .monospacedDigit()

            Text(frame.topLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}
