//
//  Models.swift
//  ClipTag
//
//  Created by Lehshak Teelockchand on 2026-08-17.
//

import CoreGraphics
import Foundation
import Vision

nonisolated struct Classification: Hashable {
    let label: String
    let confidence: Float
}

nonisolated struct Keyframe: Identifiable {
    let id = UUID()
    let index: Int
    let time: TimeInterval
    let image: CGImage
    let classifications: [Classification]
    let sharpness: Double
    let faceCount: Int

    /// Retained so SceneDetector can measure frame-to-frame distance without a
    /// second Vision pass over every frame.
    let featurePrint: VNFeaturePrintObservation?

    /// Colour histogram, used for scene detection wherever feature prints are
    /// unavailable because Core ML didn't start.
    let histogram: [Double]

    /// Filled in once the whole clip is analyzed, since the score is relative to
    /// the sharpest frame in the set.
    var thumbnailScore: Double = 0
    var normalizedSharpness: Double = 0

    var topLabel: String { classifications.first?.label ?? "unknown" }
    var topConfidence: Float { classifications.first?.confidence ?? 0 }

    /// Whether the Core ML backed requests produced anything for this frame.
    var usedCoreML: Bool { !classifications.isEmpty || featurePrint != nil }
}

/// Named VideoScene rather than Scene to avoid colliding with SwiftUI.Scene.
nonisolated struct VideoScene: Identifiable {
    let id = UUID()
    let startTime: TimeInterval
    let endTime: TimeInterval
    let keyframes: [Keyframe]

    var duration: TimeInterval { endTime - startTime }

    var representativeFrame: Keyframe? {
        keyframes.max { $0.sharpness < $1.sharpness }
    }

    var dominantLabel: String {
        let counts = keyframes.reduce(into: [String: Int]()) { tally, frame in
            tally[frame.topLabel, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }?.key ?? "unknown"
    }
}

nonisolated struct Tag: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let averageConfidence: Float
    let frameCount: Int

    /// Frequency across the clip weighted by classifier confidence, so a label
    /// seen once at high confidence doesn't outrank a recurring subject.
    var relevance: Float { averageConfidence * Float(frameCount) }
}

nonisolated struct AnalysisMetrics {
    let framesProcessed: Int
    let analysisDuration: TimeInterval
    let videoDuration: TimeInterval
    let concurrency: Int

    var msPerFrame: Double {
        guard framesProcessed > 0 else { return 0 }
        return analysisDuration * 1000 / Double(framesProcessed)
    }

    /// Seconds of footage analyzed per second of wall clock.
    var realtimeFactor: Double {
        guard analysisDuration > 0 else { return 0 }
        return videoDuration / analysisDuration
    }
}

nonisolated struct AnalysisResult {
    let keyframes: [Keyframe]
    let scenes: [VideoScene]
    let tags: [Tag]
    let bestThumbnail: Keyframe?
    let metrics: AnalysisMetrics
    let settings: AnalysisSettings

    /// False when Core ML never started, so the UI can say the tags are missing
    /// rather than implying the clip had nothing in it.
    let classificationAvailable: Bool
}
