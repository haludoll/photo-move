import Foundation
import MediaLibraryDomain

/// プレゼンテーション層におけるMediaErrorの拡張
/// ローカライズされたエラーメッセージを提供
extension MediaError {
    /// ユーザー向けのローカライズされたエラーメッセージ
    var localizedMessage: String {
        switch self {
        case .invalidMediaID:
            String(localized: "Invalid media ID")
        case .invalidFilePath:
            String(localized: "Invalid file path")
        case .invalidThumbnailData:
            String(localized: "Invalid thumbnail data")
        case .permissionDenied:
            String(localized: "Photo library access permission denied. Please allow access in Settings.")
        case .mediaNotFound:
            String(localized: "Photo not found")
        case .unsupportedFormat:
            String(localized: "Unsupported file format")
        case .thumbnailGenerationFailed:
            String(localized: "Thumbnail generation failed")
        case .mediaLoadFailed:
            String(localized: "Photo loading failed")
        }
    }
}
