//
//  SceneDetector.swift
//  ClipTag
//
//  Created by Lehshak Teelockchand on 2026-08-17.
//

import Foundation
import Vision

/// Groups keyframes into scenes by comparing Vision feature prints between
/// consecutive frames. A hard cut moves the embedding far more than camera
/// motion within a single shot does.
nonisolated struct SceneDetector {

    /// Vision's feature-print distances are unitless, so this was tuned by eye on
    /// short-form footage. It is the first knob to turn if cuts are over- or
    /// under-detected, which is why the Tuning tab exposes it.
    var cutThreshold: Float = 18.0

    /// Histogram-intersection distance used when feature prints are missing.
    /// Scaled off cutThreshold so the one slider still governs sensitivity.
    var histogramThreshold: Double { Double(cutThreshold) / 50.0 }

    func scenes(from keyframes: [Keyframe], videoDuration: TimeInterval) -> [VideoScene] {
        guard let first = keyframes.first else { return [] }

        var scenes: [VideoScene] = []
        var current: [Keyframe] = [first]

        for index in 1..<keyframes.count {
            let frame = keyframes[index]

            if isCut(from: keyframes[index - 1], to: frame) {
                scenes.append(
                    VideoScene(
                        startTime: current[0].time,
                        endTime: frame.time,
                        keyframes: current
                    )
                )
                current = [frame]
            } else {
                current.append(frame)
            }
        }

        if let start = current.first {
            scenes.append(
                VideoScene(
                    startTime: start.time,
                    endTime: max(videoDuration, start.time),
                    keyframes: current
                )
            )
        }

        return scenes
    }

    /// Exposed so the frame browser can show why a boundary landed where it did.
    func distance(from previous: Keyframe, to frame: Keyframe) -> Float? {
        guard let before = previous.featurePrint, let after = frame.featurePrint else {
            return nil
        }
        var distance = Float(0)
        guard (try? before.computeDistance(&distance, to: after)) != nil else { return nil }
        return distance
    }

    private func isCut(from previous: Keyframe, to frame: Keyframe) -> Bool {
        if let distance = distance(from: previous, to: frame) {
            return distance > cutThreshold
        }

        // No feature prints means Core ML never started. Colour histograms still
        // separate hard cuts, so scene detection degrades rather than vanishing.
        if let histogramDistance = FrameSignature.distance(previous.histogram, frame.histogram) {
            return histogramDistance > histogramThreshold
        }

        return false
    }
}
