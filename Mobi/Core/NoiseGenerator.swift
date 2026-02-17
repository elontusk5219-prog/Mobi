//
//  NoiseGenerator.swift
//  Mobi
//
//  Procedural noise texture — no image assets. Used by .rough material.
//

import SwiftUI
import UIKit

enum NoiseGenerator {

    private static let lock = NSLock()
    private static var cache: [String: UIImage] = [:]

    /// Generates a tiled noise image with random alpha (0...intensity). Procedural only; no Assets.
    /// - Parameters:
    ///   - width: Tile width (e.g. 512).
    ///   - height: Tile height (e.g. 512).
    ///   - intensity: Max alpha per pixel, 0.0...1.0.
    /// - Returns: SwiftUI `Image`; use `.resizable(resizingMode: .tile)` to tile over large areas.
    static func generateNoiseImage(width: CGFloat, height: CGFloat, intensity: CGFloat) -> Image {
        let w = Int(width)
        let h = Int(height)
        let key = "\(w)_\(h)_\(intensity)"
        lock.lock()
        if let cached = cache[key] {
            lock.unlock()
            return Image(uiImage: cached)
        }
        lock.unlock()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = w * bytesPerPixel
        guard let context = CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return Image(systemName: "square.fill")
        }

        let buffer = context.data!.assumingMemoryBound(to: UInt8.self)
        let clampedIntensity = max(0, min(1, intensity))
        let maxAlpha = UInt8(clampedIntensity * 255)

        for y in 0..<h {
            for x in 0..<w {
                let offset = (y * w + x) * bytesPerPixel
                buffer[offset + 0] = 255  // R
                buffer[offset + 1] = 255  // G
                buffer[offset + 2] = 255  // B
                buffer[offset + 3] = maxAlpha > 0 ? UInt8.random(in: 0...maxAlpha) : 0
            }
        }

        guard let cgImage = context.makeImage() else {
            return Image(systemName: "square.fill")
        }
        let uiImage = UIImage(cgImage: cgImage)
        lock.lock()
        cache[key] = uiImage
        lock.unlock()

        return Image(uiImage: uiImage)
    }
}
