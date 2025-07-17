import Dependencies
import DependencyInjection
import Domain
import Foundation
import Photos

/// フォトライブラリの操作を提供するApplicationサービス
@available(iOS 15.0, macOS 11.0, *)
package struct MediaLibraryService: Sendable {

    // MARK: - Dependencies

    @Dependency(\.mediaRepository) private var mediaRepository

    // MARK: - Initialization

    package init() {}

    // MARK: - Public Methods

    /// メディア一覧を取得する
    /// - Returns: メディア一覧
    /// - Throws: MediaError
    package func loadMedia() async throws -> [Media] {
        let permissionStatus = checkPermissionStatus()

        switch permissionStatus {
        case .notDetermined:
            let requestedStatus = await requestPermission()
            guard requestedStatus == .authorized || requestedStatus == .limited else {
                throw MediaError.permissionDenied
            }
        case .denied, .restricted:
            throw MediaError.permissionDenied
        case .authorized, .limited:
            break
        }

        return try await mediaRepository.fetchMedia()
    }

    /// 指定されたメディアのサムネイルを取得する
    /// - Parameters:
    ///   - mediaID: メディアID
    ///   - size: サムネイルサイズ
    /// - Returns: サムネイルデータ
    /// - Throws: MediaError
    package func loadThumbnail(for mediaID: Media.ID, size: CGSize) async throws -> Media.Thumbnail {
        return try await mediaRepository.fetchThumbnail(for: mediaID, size: size)
    }

    // MARK: - Private Methods

    /// Photo library access permission status
    /// - Returns: Permission status
    private func checkPermissionStatus() -> PhotoLibraryPermissionStatus {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    /// Request photo library access permission
    /// - Returns: Permission status after request
    private func requestPermission() async -> PhotoLibraryPermissionStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        switch status {
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }
}
