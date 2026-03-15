import UIKit

// MARK: - Image Quality

/// Estimated quality level of a screenshot based on resolution.
enum ImageQuality: Sendable {
    /// Resolution > 720p — ideal for extraction.
    case good
    /// Resolution between 480p and 720p — usable but may lose some detail.
    case acceptable
    /// Resolution < 480p — likely too low for reliable text extraction.
    case poor

    var displayMessage: String {
        switch self {
        case .good:
            return "Bonne qualite - resolution suffisante."
        case .acceptable:
            return "Qualite acceptable - certains details pourraient etre perdus."
        case .poor:
            return "Qualite insuffisante - le texte pourrait ne pas etre lisible. Essayez un screenshot en meilleure resolution."
        }
    }
}

// MARK: - Image Processor Errors

enum ImageProcessorError: LocalizedError {
    case compressionFailed
    case imageTooLarge(sizeMB: Double)
    case invalidImageFormat
    case imageIsEmpty

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image to JPEG."
        case .imageTooLarge(let sizeMB):
            return String(format: "Image is too large (%.1f MB). Maximum is 5 MB.", sizeMB)
        case .invalidImageFormat:
            return "Image format is not supported. Use JPEG or PNG."
        case .imageIsEmpty:
            return "Image data is empty."
        }
    }
}

// MARK: - Image Processor

/// Prepares images for upload to the backend.
///
/// Handles EXIF orientation normalization, resizing, and JPEG compression
/// to ensure uploads are fast and within the backend's size expectations.
enum ImageProcessor {

    // MARK: - Constants

    /// Maximum dimension (width or height) for the uploaded image.
    private static let maxDimension: CGFloat = 1920

    /// Target JPEG compression quality (0.0–1.0).
    private static let jpegQuality: CGFloat = 0.6

    /// Absolute maximum file size the backend accepts.
    private static let maxFileSize: Int = 5 * 1024 * 1024 // 5 MB

    /// Threshold for "good" quality: longest side >= 720p.
    private static let goodQualityThreshold: CGFloat = 1280

    /// Threshold for "acceptable" quality: longest side >= 480p.
    private static let acceptableQualityThreshold: CGFloat = 640

    // MARK: - Public API

    /// Compress and prepare an image for upload.
    ///
    /// 1. Normalizes EXIF orientation so the image is right-side up.
    /// 2. Resizes to a maximum of 1920px on the longest side, preserving aspect ratio.
    /// 3. Compresses to JPEG at quality 0.6, targeting 200–400 KB.
    ///
    /// If the initial compression exceeds 500 KB, a second pass at lower quality is attempted.
    ///
    /// - Parameter image: The source `UIImage` (from camera, PhotosPicker, etc.).
    /// - Returns: JPEG `Data` ready for multipart upload.
    /// - Throws: `ImageProcessorError` if compression fails.
    static func compressForUpload(image: UIImage) throws -> Data {
        // Step 1: Fix EXIF orientation
        let oriented = image.fixedOrientation()

        // Step 2: Resize if needed
        let resized = resizeIfNeeded(oriented, maxDimension: maxDimension)

        // Step 3: Compress to JPEG
        guard let jpegData = resized.jpegData(compressionQuality: jpegQuality) else {
            throw ImageProcessorError.compressionFailed
        }

        // Step 4: If still too large, try progressively lower quality
        if jpegData.count > 500_000 {
            // Try quality 0.4
            if let reduced = resized.jpegData(compressionQuality: 0.4), reduced.count < jpegData.count {
                if reduced.count > maxFileSize {
                    // One more attempt at even lower quality with a smaller resize
                    let smaller = resizeIfNeeded(oriented, maxDimension: 1280)
                    if let finalData = smaller.jpegData(compressionQuality: 0.4) {
                        if finalData.count > maxFileSize {
                            throw ImageProcessorError.imageTooLarge(
                                sizeMB: Double(finalData.count) / 1_048_576.0
                            )
                        }
                        return finalData
                    }
                }
                return reduced
            }
        }

        if jpegData.count > maxFileSize {
            throw ImageProcessorError.imageTooLarge(
                sizeMB: Double(jpegData.count) / 1_048_576.0
            )
        }

        return jpegData
    }

    /// Validate raw image data before processing.
    ///
    /// Checks:
    /// - The data is not empty.
    /// - The data starts with JPEG or PNG magic bytes.
    /// - The data does not exceed 5 MB.
    ///
    /// - Parameter data: Raw bytes of the image file.
    /// - Returns: `true` if the data passes all validation checks.
    static func validateImage(data: Data) -> Bool {
        guard !data.isEmpty else { return false }
        guard data.count <= maxFileSize else { return false }
        guard isJPEG(data) || isPNG(data) else { return false }
        return true
    }

    /// Estimate the quality of an image for screenshot analysis.
    ///
    /// Based on the longer dimension:
    /// - `.good` if > 1280px (effectively >720p landscape).
    /// - `.acceptable` if between 640px and 1280px.
    /// - `.poor` if < 640px.
    ///
    /// - Parameter image: The `UIImage` to evaluate.
    /// - Returns: An `ImageQuality` assessment.
    static func estimateQuality(image: UIImage) -> ImageQuality {
        let scale = image.scale
        let longestSide = max(image.size.width * scale, image.size.height * scale)

        if longestSide >= goodQualityThreshold {
            return .good
        } else if longestSide >= acceptableQualityThreshold {
            return .acceptable
        } else {
            return .poor
        }
    }

    // MARK: - Private Helpers

    /// Resize an image so its longest side does not exceed `maxDimension`.
    /// Preserves aspect ratio. Returns the original image if already small enough.
    private static func resizeIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)

        guard longestSide > maxDimension else { return image }

        let scale = maxDimension / longestSide
        let newSize = CGSize(
            width: (size.width * scale).rounded(.down),
            height: (size.height * scale).rounded(.down)
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Check if data starts with the JPEG magic bytes (FF D8 FF).
    private static func isJPEG(_ data: Data) -> Bool {
        guard data.count >= 3 else { return false }
        return data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF
    }

    /// Check if data starts with the PNG magic bytes (89 50 4E 47 0D 0A 1A 0A).
    private static func isPNG(_ data: Data) -> Bool {
        guard data.count >= 8 else { return false }
        let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        return data.prefix(8).elementsEqual(pngSignature)
    }
}

// MARK: - UIImage + EXIF Orientation Fix

extension UIImage {

    /// Returns a copy of the image with its orientation normalized to `.up`.
    ///
    /// This is critical before uploading because:
    /// - iOS cameras encode orientation in EXIF metadata rather than rotating pixels.
    /// - JPEG compression may strip EXIF, causing the server to see a rotated image.
    /// - Claude Vision works best with correctly oriented images.
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        guard let cgImage = self.cgImage else { return self }

        let width = cgImage.width
        let height = cgImage.height

        var transform = CGAffineTransform.identity

        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: CGFloat(width), y: CGFloat(height))
            transform = transform.rotated(by: .pi)

        case .left, .leftMirrored:
            transform = transform.translatedBy(x: CGFloat(height), y: 0)
            transform = transform.rotated(by: .pi / 2)

        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: CGFloat(width))
            transform = transform.rotated(by: -.pi / 2)

        case .up, .upMirrored:
            break

        @unknown default:
            break
        }

        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: CGFloat(width), y: 0)
            transform = transform.scaledBy(x: -1, y: 1)

        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: CGFloat(height), y: 0)
            transform = transform.scaledBy(x: -1, y: 1)

        default:
            break
        }

        let contextWidth: Int
        let contextHeight: Int

        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            contextWidth = height
            contextHeight = width
        default:
            contextWidth = width
            contextHeight = height
        }

        guard let colorSpace = cgImage.colorSpace,
              let context = CGContext(
                data: nil,
                width: contextWidth,
                height: contextHeight,
                bitsPerComponent: cgImage.bitsPerComponent,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: cgImage.bitmapInfo.rawValue
              )
        else {
            // Fallback: use UIGraphicsImageRenderer as a simpler alternative
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { _ in
                draw(at: .zero)
            }
        }

        context.concatenate(transform)

        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(height), height: CGFloat(width)))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        }

        guard let newCGImage = context.makeImage() else {
            return self
        }

        return UIImage(cgImage: newCGImage)
    }
}
