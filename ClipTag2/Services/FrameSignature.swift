//
//  FrameSignature.swift
//  ClipTag
//
//  Created by Lehshak Teelockchand on 2026-08-17.
//

import CoreGraphics

/// Coarse RGB histogram used as a scene-cut signal when Vision feature prints
/// aren't available. A learned embedding separates shots far more precisely, but
/// a hard cut moves the colour distribution enough to be caught without Core ML —
/// which keeps scene detection working on Simulator runtimes where Espresso fails
/// to start.
nonisolated enum FrameSignature {

    static func histogram(
        for image: CGImage,
        binsPerChannel: Int = 8,
        sampleWidth: Int = 64
    ) -> [Double] {
        guard let pixels = rgbaPixels(from: image, width: sampleWidth), !pixels.isEmpty else {
            return []
        }

        var bins = [Double](repeating: 0, count: binsPerChannel * 3)
        let scale = Double(binsPerChannel) / 256.0
        var samples = 0.0

        for offset in stride(from: 0, to: pixels.count - 3, by: 4) {
            for channel in 0..<3 {
                let bin = min(Int(Double(pixels[offset + channel]) * scale), binsPerChannel - 1)
                bins[channel * binsPerChannel + bin] += 1
            }
            samples += 1
        }

        guard samples > 0 else { return [] }
        return bins.map { $0 / (samples * 3) }
    }

    /// Histogram intersection expressed as a distance: 0 for identical colour
    /// distributions, 1 for no overlap at all.
    static func distance(_ lhs: [Double], _ rhs: [Double]) -> Double? {
        guard !lhs.isEmpty, lhs.count == rhs.count else { return nil }
        let intersection = zip(lhs, rhs).reduce(0.0) { $0 + min($1.0, $1.1) }
        return 1 - intersection
    }

    private static func rgbaPixels(from image: CGImage, width: Int) -> [UInt8]? {
        let targetWidth = max(1, min(width, image.width))
        let scale = Double(targetWidth) / Double(image.width)
        let targetHeight = max(1, Int(Double(image.height) * scale))
        let bytesPerRow = targetWidth * 4

        var buffer = [UInt8](repeating: 0, count: bytesPerRow * targetHeight)

        let drew = buffer.withUnsafeMutableBytes { raw -> Bool in
            guard let base = raw.baseAddress,
                  let context = CGContext(
                      data: base,
                      width: targetWidth,
                      height: targetHeight,
                      bitsPerComponent: 8,
                      bytesPerRow: bytesPerRow,
                      space: CGColorSpaceDeviceRGB(),
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  )
            else { return false }

            context.draw(
                image,
                in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
            )
            return true
        }

        return drew ? buffer : nil
    }

    private static func CGColorSpaceDeviceRGB() -> CGColorSpace {
        CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
    }
}
