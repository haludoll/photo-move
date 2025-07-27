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
            String(localized: "Invalid media ID", bundle: .module)
        case .invalidFilePath:
            String(localized: "Invalid file path", bundle: .module)
        case .invalidThumbnailData:
            String(localized: "Invalid thumbnail data", bundle: .module)
        case .permissionDenied:
            String(localized: "Photo library access permission denied. Please allow access in Settings.", bundle: .module)
        case .mediaNotFound:
            String(localized: "Photo not found", bundle: .module)
        case .unsupportedFormat:
            String(localized: "Unsupported file format", bundle: .module)
        case .thumbnailGenerationFailed:
            String(localized: "Thumbnail generation failed", bundle: .module)
        case .mediaLoadFailed:
            String(localized: "Photo loading failed", bundle: .module)
        }
    }
}
