import Foundation
import ImageIO

/// Datum pořízení z EXIF/TIFF metadat pro tlačítko „Seřadit dle EXIF“
/// (uživatel zvolil tuto funkci — spec §11, ot. 6).
enum ExifDateProvider {
    static func date(for url: URL) -> Date? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }
        // Rozhodnutí dle §2 pravidla 2: časová zóna EXIF se ignoruje, použije se lokální čas.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"

        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
           let raw = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String,
           let date = formatter.date(from: raw) {
            return date
        }
        if let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
           let raw = tiff[kCGImagePropertyTIFFDateTime as String] as? String,
           let date = formatter.date(from: raw) {
            return date
        }
        return nil
    }
}
