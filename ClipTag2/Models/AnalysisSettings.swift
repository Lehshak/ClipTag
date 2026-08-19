//
//  AnalysisSettings.swift
//  ClipTag
//
//  Created by Lehshak Teelockchand on 2026-08-17.
//

import Foundation

/// Every tunable in the pipeline, surfaced so the Tuning tab can drive a re-run
/// without re-importing the clip.
nonisolated struct AnalysisSettings: Equatable {

    // Sampling
    var samplesPerSecond: Double = 1.0
    var maximumFrames: Int = 120

    // Classification
    var minimumConfidence: Double = 0.05
    var maximumClassifications: Int = 5

    // Scene detection
    var cutThreshold: Double = 18.0

    // Performance
    var concurrency: Int = AnalysisSettings.defaultConcurrency

    // Thumbnail scoring
    var sharpnessWeight: Double = 0.5
    var confidenceWeight: Double = 0.3
    var faceWeight: Double = 0.2

    static let defaultConcurrency = max(2, ProcessInfo.processInfo.activeProcessorCount / 2)

    /// Normalized at scoring time so the three sliders can move independently
    /// without the caller having to keep them summing to one.
    var thumbnailWeights: (sharpness: Double, confidence: Double, face: Double) {
        let total = sharpnessWeight + confidenceWeight + faceWeight
        guard total > 0 else { return (1, 0, 0) }
        return (sharpnessWeight / total, confidenceWeight / total, faceWeight / total)
    }
}
