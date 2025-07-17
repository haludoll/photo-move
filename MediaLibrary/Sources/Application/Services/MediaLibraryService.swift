import Dependencies
import DependencyInjection
import Domain
import Foundation

/// フォトライブラリの操作を提供するApplicationサービス
@available(iOS 15.0, macOS 11.0, *)
package struct MediaLibraryService: Sendable {

    // MARK: - Dependencies

    @Dependency(\.mediaRepository) private var mediaRepository
    @Dependency(\.photoLibraryPermissionService) private var permissionService

    // MARK: - Initialization

    package init() {}

    // MARK: - Public Methods

    /// メディア一覧を取得する
    /// - Returns: メディア一覧
    /// - Throws: MediaError
    package func loadMedia() async throws -> [Media] {
        let permissionStatus = permissionService.checkPermissionStatus()

        switch permissionStatus {
        case .notDetermined:
            let requestedStatus = await permissionService.requestPermission()
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
}
