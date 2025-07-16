import Foundation

/// メディア関連のドメインエラー
enum MediaError: Error, LocalizedError {
    case invalidMediaID
    case invalidFilePath
    case invalidThumbnailData
    case permissionDenied
    case mediaNotFound
    case unsupportedFormat
    case thumbnailGenerationFailed
    case mediaLoadFailed

    var errorDescription: String? {
        switch self {
        case .invalidMediaID:
            "Invalid media ID"
        case .invalidFilePath:
            "Invalid file path"
        case .invalidThumbnailData:
            "Invalid thumbnail data"
        case .permissionDenied:
            "Photo library access permission denied"
        case .mediaNotFound:
            "Media not found"
        case .unsupportedFormat:
            "Unsupported file format"
        case .thumbnailGenerationFailed:
            "Thumbnail generation failed"
        case .mediaLoadFailed:
            "Media loading failed"
        }
    }
}
