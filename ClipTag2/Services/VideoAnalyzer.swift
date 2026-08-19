//
//  VideoAnalyzer.swift
//  ClipTag
//
//  Created by Lehshak Teelockchand on 2026-08-17.
//

import AVFoundation
import Foundation

nonisolated enum AnalysisError: LocalizedError {
    case noFramesExtracted

    var errorDescription: String? {
        switch self {
        case .noFramesExtracted:
            "No frames could be read from that clip. It may be an unsupported format."
        }
    }
}

/// Orchestrates the pipeline: extract frames, analyze each one, then fold the
/// per-frame observations into scenes, tags, and a thumbnail pick.
nonisolated struct VideoAnalyzer {
    var settings: AnalysisSettings = AnalysisSettings()

    func analyze(
        url: URL,
        progress: @escaping (Double) -> Void = { _ in }
    ) async throws -> AnalysisResult {
        let started = Date()

        let extractor = KeyframeExtractor(
            samplesPerSecond: settings.samplesPerSecond,
            maximumFrames: settings.maximumFrames
        )
        let frameAnalyzer = FrameAnalyzer(
            maximumClassifications: settings.maximumClassifications,
            minimumConfidence: Float(settings.minimumConfidence)
        )
        let sceneDetector = SceneDetector(cutThreshold: Float(settings.cutThreshold))

        let asset = AVURLAsset(url: url)
        let (extracted, videoDuration) = try await extractor.extract(from: asset)
        guard !extracted.isEmpty else { throw AnalysisError.noFramesExtracted }

        var keyframes = await analyzeFrames(
            extracted,
            using: frameAnalyzer,
            progress: progress
        )
        guard !keyframes.isEmpty else { throw AnalysisError.noFramesExtracted }

        // Core ML failing to start is a degraded run, not a failed one: sharpness,
        // faces, and histogram-based scene cuts all still work, so surface the gap
        // in the result rather than throwing the whole analysis away.
        let classificationAvailable = keyframes.contains(where: \.usedCoreML)

        scoreForThumbnail(&keyframes)

        return AnalysisResult(
            keyframes: keyframes,
            scenes: sceneDetector.scenes(from: keyframes, videoDuration: videoDuration),
            tags: aggregateTags(from: keyframes),
            bestThumbnail: keyframes.max { $0.thumbnailScore < $1.thumbnailScore },
            metrics: AnalysisMetrics(
                framesProcessed: keyframes.count,
                analysisDuration: Date().timeIntervalSince(started),
                videoDuration: videoDuration,
                concurrency: settings.concurrency
            ),
            settings: settings,
            classificationAvailable: classificationAvailable
        )
    }

    private func analyzeFrames(
        _ frames: [ExtractedFrame],
        using frameAnalyzer: FrameAnalyzer,
        progress: @escaping (Double) -> Void
    ) async -> [Keyframe] {
        let lanes = max(1, settings.concurrency)
        var keyframes: [Keyframe] = []
        keyframes.reserveCapacity(frames.count)
        var completed = 0

        for start in stride(from: 0, to: frames.count, by: lanes) {
            let batch = Array(frames[start..<min(start + lanes, frames.count)])

            let analyzed = await withTaskGroup(of: Keyframe.self) { group in
                for frame in batch {
                    group.addTask {
                        let analysis = frameAnalyzer.analyze(frame.image)
                        return Keyframe(
                            index: frame.index,
                            time: frame.time,
                            image: frame.image,
                            classifications: analysis.classifications,
                            sharpness: Sharpness.score(for: frame.image),
                            faceCount: analysis.faceCount,
                            featurePrint: analysis.featurePrint,
                            histogram: FrameSignature.histogram(for: frame.image)
                        )
                    }
                }

                var results: [Keyframe] = []
                for await keyframe in group { results.append(keyframe) }
                return results
            }

            keyframes.append(contentsOf: analyzed)
            completed += batch.count
            progress(Double(completed) / Double(frames.count))
        }

        // Task groups finish out of order; scene detection needs chronology.
        return keyframes.sorted { $0.index < $1.index }
    }

    /// Sharpness dominates so blurry frames lose outright, classifier confidence
    /// breaks ties between equally sharp frames, and a visible face edges ahead
    /// of an empty shot. Weights are user-adjustable in the Tuning tab.
    private func scoreForThumbnail(_ keyframes: inout [Keyframe]) {
        let peak = keyframes.map(\.sharpness).max() ?? 0
        let weights = settings.thumbnailWeights

        for index in keyframes.indices {
            let normalized = peak > 0 ? keyframes[index].sharpness / peak : 0
            keyframes[index].normalizedSharpness = normalized
            keyframes[index].thumbnailScore =
                weights.sharpness * normalized
                + weights.confidence * Double(keyframes[index].topConfidence)
                + weights.face * (keyframes[index].faceCount > 0 ? 1 : 0)
        }
    }

    private func aggregateTags(from keyframes: [Keyframe]) -> [Tag] {
        var totals: [String: (confidence: Float, count: Int)] = [:]

        for frame in keyframes {
            for classification in frame.classifications {
                let running = totals[classification.label] ?? (0, 0)
                totals[classification.label] = (
                    running.confidence + classification.confidence,
                    running.count + 1
                )
            }
        }

        return totals
            .map { label, running in
                Tag(
                    label: label,
                    averageConfidence: running.confidence / Float(running.count),
                    frameCount: running.count
                )
            }
            .sorted { $0.relevance > $1.relevance }
    }
}
