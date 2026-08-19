//
//  Sharpness.swift
//  ClipTag
//
//  Created by Lehshak Teelockchand on 2026-08-17.
//

import CoreGraphics

/// Blur detection by variance of the Laplacian: a blurry frame has little
/// high-frequency energy, so its second derivative varies less across the image.
/// Used to keep soft or motion-blurred frames from being picked as thumbnails.
nonisolated enum Sharpness {

    static func score(for image: CGImage, sampleWidth: Int = 160) -> Double {
        guard let (pixels, width, height) = grayscalePixels(from: image, width: sampleWidth),
              width > 2, height > 2 else { return 0 }

        var sum = 0.0
        var sumOfSquares = 0.0
        var count = 0.0

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let i = y * width + x
                let laplacian = 4.0 * Double(pixels[i])
                    - Double(pixels[i - 1])
                    - Double(pixels[i + 1])
                    - Double(pixels[i - width])
                    - Double(pixels[i + width])

                sum += laplacian
                sumOfSquares += laplacian * laplacian
                count += 1
            }
        }

        guard count > 0 else { return 0 }
        let mean = sum / count
        return max(0, sumOfSquares / count - mean * mean)
    }

    private static func grayscalePixels(
        from image: CGImage,
        width: Int
    ) -> (pixels: [UInt8], width: Int, height: Int)? {
        let targetWidth = max(1, min(width, image.width))
        let scale = Double(targetWidth) / Double(image.width)
        let targetHeight = max(1, Int(Double(image.height) * scale))

        var buffer = [UInt8](repeating: 0, count: targetWidth * targetHeight)

        let drew = buffer.withUnsafeMutableBytes { raw -> Bool in
            guard let base = raw.baseAddress,
                  let context = CGContext(
                      data: base,
                      width: targetWidth,
                      height: targetHeight,
                      bitsPerComponent: 8,
                      bytesPerRow: targetWidth,
                      space: CGColorSpaceCreateDeviceGray(),
                      bitmapInfo: CGImageAlphaInfo.none.rawValue
                  )
            else { return false }

            context.draw(
                image,
                in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
            )
            return true
        }

        return drew ? (buffer, targetWidth, targetHeight) : nil
    }
}
