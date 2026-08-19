//
//  KeyframeExtractor.swift
//  ClipTag
//
//  Created by Lehshak Teelockchand on 2026-08-17.
//

import AVFoundation
import CoreGraphics

nonisolated struct ExtractedFrame {
    let index: Int
    let time: TimeInterval
    let image: CGImage
}

nonisolated struct KeyframeExtractor {
    /// How densely to sample the clip. One frame per second catches scene changes
    /// in short-form video without multiplying analysis cost.
    var samplesPerSecond: Double = 1.0

    /// Guards against a long import turning into a multi-minute analysis. Past
    /// this count the sampling interval widens to cover the clip evenly.
    var maximumFrames: Int = 120

    /// Vision downscales internally anyway, so decoding at full resolution only
    /// costs memory.
    var maximumSize = CGSize(width: 480, height: 480)

    func extract(from asset: AVURLAsset) async throws -> (frames: [ExtractedFrame], duration: TimeInterval) {
        let duration = CMTimeGetSeconds(try await asset.load(.duration))
        guard duration.isFinite, duration > 0 else { return ([], 0) }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = maximumSize

        // Exact-frame seeking forces a decode from the preceding keyframe for every
        // sample, which is slow and fragile on software decoders. At this sampling
        // rate a quarter second of slack costs nothing.
        let tolerance = CMTime(seconds: 0.25, preferredTimescale: 600)
        generator.requestedTimeToleranceBefore = tolerance
        generator.requestedTimeToleranceAfter = tolerance

        let step = max(1.0 / max(samplesPerSecond, 0.1), duration / Double(maximumFrames))

        var frames: [ExtractedFrame] = []
        var timestamp = 0.0
        var index = 0

        while timestamp < duration && frames.count < maximumFrames {
            let time = CMTime(seconds: timestamp, preferredTimescale: 600)

            // A frame that fails to decode shouldn't abort the whole analysis.
            if let (image, actualTime) = try? await generator.image(at: time) {
                frames.append(
                    ExtractedFrame(
                        index: index,
                        time: CMTimeGetSeconds(actualTime),
                        image: image
                    )
                )
                index += 1
            }

            timestamp += step
        }

        return (frames, duration)
    }
}
