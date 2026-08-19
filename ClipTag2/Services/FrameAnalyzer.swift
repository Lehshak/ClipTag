//
//  FrameAnalyzer.swift
//  ClipTag
//
//  Created by Lehshak Teelockchand on 2026-08-17.
//

import CoreGraphics
import Vision

nonisolated struct FrameAnalysis {
    let classifications: [Classification]
    let faceCount: Int
    let featurePrint: VNFeaturePrintObservation?
}

/// Runs the per-frame Vision work. Everything here uses classifiers built into
/// the OS, so the app ships no model files and makes no network calls.
nonisolated struct FrameAnalyzer {
    var maximumClassifications = 5
    var minimumConfidence: Float = 0.05

    func analyze(_ image: CGImage) -> FrameAnalysis {
        // A fresh handler per frame keeps this safe to call from several tasks.
        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        // Performed separately so one unavailable request doesn't void the rest.
        // Face detection is classical CV and keeps working when Core ML doesn't.
        let classify = VNClassifyImageRequest()
        try? handler.perform([classify])

        let faces = VNDetectFaceRectanglesRequest()
        try? handler.perform([faces])

        let featurePrint = VNGenerateImageFeaturePrintRequest()
        try? handler.perform([featurePrint])

        let classifications = (classify.results ?? [])
            .filter { $0.confidence >= minimumConfidence }
            .prefix(maximumClassifications)
            .map { Classification(label: $0.identifier, confidence: $0.confidence) }

        return FrameAnalysis(
            classifications: Array(classifications),
            faceCount: faces.results?.count ?? 0,
            featurePrint: featurePrint.results?.first
        )
    }
}
