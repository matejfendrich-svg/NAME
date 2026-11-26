import Foundation
import AppKit
import ImageIO

/// Asynchronní generování miniatur přes ImageIO (§8), aby okno neblokovalo.
/// Cache klíčovaná cestou + datem modifikace; při více než 200 fotkách zůstává plynulé (§9.6).
final class ThumbnailProvider {
    static let shared = ThumbnailProvider()

    private let cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 400
    }

    func thumbnail(for url: URL, maxPixelSize: Int) -> NSImage? {
        let modification: TimeInterval
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let date = attrs[.modificationDate] as? Date {
            modification = date.timeIntervalSince1970
        } else {
            modification = 0
        }
        let key = "\(url.path)#\(modification)#\(maxPixelSize)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let image: NSImage?
        if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
           let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
           ] as CFDictionary) {
            image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        } else if let fallback = NSImage(contentsOfFile: url.path) {
            image = fallback
        } else {
            // Např. RAW, který ImageIO neumí dekódovat — černobílý zástupný symbol.
            image = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)
        }

        if let image {
            cache.setObject(image, forKey: key)
        }
        return image
    }
}
