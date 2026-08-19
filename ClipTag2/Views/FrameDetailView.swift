//
//  FrameDetailView.swift
//  ClipTag
//
//  Created by Lehshak Teelockchand on 2026-08-17.
//

import SwiftUI

struct FrameDetailView: View {
    let frame: Keyframe
    let isThumbnail: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    Image(decorative: frame.image, scale: 1, orientation: .up)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    if isThumbnail {
                        Label("Chosen as the suggested thumbnail", systemImage: "star.fill")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                    }

                    measurements
                    classifications
                }
                .padding()
            }
            .navigationTitle("\(frame.time, format: .number.precision(.fractionLength(2)))s")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var measurements: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Measurements", detail: "What this frame contributed to the thumbnail score.")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                StatTile(
                    value: String(format: "%.2f", frame.thumbnailScore),
                    label: "thumbnail score",
                    systemImage: "star"
                )
                StatTile(
                    value: String(format: "%.0f%%", frame.normalizedSharpness * 100),
                    label: "sharpness vs. sharpest frame",
                    systemImage: "camera.aperture"
                )
                StatTile(
                    value: "\(frame.faceCount)",
                    label: frame.faceCount == 1 ? "face detected" : "faces detected",
                    systemImage: "person.crop.square"
                )
                StatTile(
                    value: "#\(frame.index)",
                    label: "sample index",
                    systemImage: "number"
                )
            }
        }
    }

    @ViewBuilder
    private var classifications: some View {
        if frame.classifications.isEmpty {
            Text("No classifications above the confidence threshold.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader("Classifications", detail: "Top labels Vision returned for this frame.")

                VStack(spacing: 12) {
                    ForEach(frame.classifications, id: \.self) { classification in
                        ScoreBar(
                            label: classification.label,
                            value: Double(classification.confidence),
                            detail: "\(Int((classification.confidence * 100).rounded()))%"
                        )
                    }
                }
            }
        }
    }
}
