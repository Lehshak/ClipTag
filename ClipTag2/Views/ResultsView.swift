//
//  ResultsView.swift
//  ClipTag
//
//  Created by Lehshak Teelockchand on 2026-08-17.
//

import SwiftUI

struct ResultsView: View {
    let result: AnalysisResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                if !result.classificationAvailable {
                    degradedBanner
                }
                thumbnailSection
                metricsSection
                tagSection
                sceneSection
            }
            .padding()
        }
    }

    private var degradedBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 3) {
                Text("Running without Core ML")
                    .font(.subheadline.weight(.semibold))
                Text("Classification is unavailable here, so there are no tags. Scene cuts fell back to colour histograms. Run on a physical device for the full pipeline.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var thumbnailSection: some View {
        if let thumbnail = result.bestThumbnail {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    "Suggested Thumbnail",
                    detail: "Highest combined score across sharpness, subject confidence, and face presence."
                )

                ZStack(alignment: .bottomLeading) {
                    Image(decorative: thumbnail.image, scale: 1, orientation: .up)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)

                    LinearGradient(
                        colors: [.black.opacity(0.75), .clear],
                        startPoint: .bottom,
                        endPoint: .center
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(thumbnail.topLabel)
                            .font(.title3.weight(.semibold))
                        Text("at \(thumbnail.time, format: .number.precision(.fractionLength(1)))s · score \(thumbnail.thumbnailScore, format: .number.precision(.fractionLength(2)))")
                            .font(.caption)
                            .opacity(0.85)
                    }
                    .foregroundStyle(.white)
                    .padding(16)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))

                scoreBreakdown(for: thumbnail)
            }
        }
    }

    private func scoreBreakdown(for frame: Keyframe) -> some View {
        let weights = result.settings.thumbnailWeights

        return VStack(spacing: 10) {
            ScoreBar(
                label: "Sharpness",
                value: frame.normalizedSharpness,
                detail: "×\(String(format: "%.2f", weights.sharpness))"
            )
            ScoreBar(
                label: "Subject confidence",
                value: Double(frame.topConfidence),
                detail: "×\(String(format: "%.2f", weights.confidence))"
            )
            ScoreBar(
                label: "Face present",
                value: frame.faceCount > 0 ? 1 : 0,
                detail: "×\(String(format: "%.2f", weights.face))"
            )
        }
        .padding(14)
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 14))
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Performance", detail: "Measured on device. No network calls, no bundled models.")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                StatTile(
                    value: "\(result.metrics.framesProcessed)",
                    label: "frames analyzed",
                    systemImage: "square.stack.3d.down.right"
                )
                StatTile(
                    value: "\(Int(result.metrics.msPerFrame.rounded()))ms",
                    label: "per frame",
                    systemImage: "timer"
                )
                StatTile(
                    value: String(format: "%.1f×", result.metrics.realtimeFactor),
                    label: "faster than realtime",
                    systemImage: "gauge.with.needle"
                )
                StatTile(
                    value: "\(result.metrics.concurrency)",
                    label: "concurrent lanes",
                    systemImage: "arrow.triangle.branch"
                )
            }
        }
    }

    @ViewBuilder
    private var tagSection: some View {
        if !result.tags.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    "Suggested Tags",
                    detail: "Ranked by how often a label appears, weighted by confidence."
                )

                FlowLayout(spacing: 8) {
                    ForEach(result.tags.prefix(14)) { tag in
                        TagChip(tag: tag)
                    }
                }
            }
        }
    }

    private var sceneSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                "Scenes",
                detail: "\(result.scenes.count) detected from feature-print distance between consecutive frames."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(Array(result.scenes.enumerated()), id: \.element.id) { index, scene in
                        SceneCard(index: index + 1, scene: scene)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

private struct SceneCard: View {
    let index: Int
    let scene: VideoScene

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let frame = scene.representativeFrame {
                Image(decorative: frame.image, scale: 1, orientation: .up)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Scene \(index)")
                    .font(.caption.weight(.semibold))
                Text(scene.dominantLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("\(String(format: "%.1f", scene.startTime))–\(String(format: "%.1f", scene.endTime))s")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: 150)
    }
}
