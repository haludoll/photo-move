import Foundation

/// メディア関連のドメインエラー
package enum MediaError: Error, LocalizedError {
    case invalidMediaID
    case invalidFilePath
    case invalidThumbnailData
    case permissionDenied
    case mediaNotFound
    case unsupportedFormat
    case thumbnailGenerationFailed
    case mediaLoadFailed

    package var errorDescription: String? {
        switch self {
        case .invalidMediaID:
            NSLocalizedString("Invalid media ID", comment: "Error message for invalid media ID")
        case .invalidFilePath:
            NSLocalizedString("Invalid file path", comment: "Error message for invalid file path")
        case .invalidThumbnailData:
            NSLocalizedString("Invalid thumbnail data", comment: "Error message for invalid thumbnail data")
        case .permissionDenied:
            NSLocalizedString("Photo library access permission denied. Please allow access in Settings.", comment: "Error message for permission denied")
        case .mediaNotFound:
            NSLocalizedString("Photo not found", comment: "Error message for media not found")
        case .unsupportedFormat:
            NSLocalizedString("Unsupported file format", comment: "Error message for unsupported format")
        case .thumbnailGenerationFailed:
            NSLocalizedString("Thumbnail generation failed", comment: "Error message for thumbnail generation failure")
        case .mediaLoadFailed:
            NSLocalizedString("Photo loading failed", comment: "Error message for media load failure")
        }
    }
}
