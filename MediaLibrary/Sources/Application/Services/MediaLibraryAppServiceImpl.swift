import Foundation
import MediaLibraryDomain

/// フォトライブラリの操作を提供するApplicationサービス実装
package struct MediaLibraryAppServiceImpl: MediaLibraryAppService {
    // MARK: - Dependencies

    private let mediaRepository: any MediaRepository
    private let permissionService: any PhotoLibraryPermissionService

    // MARK: - Initialization

    package init(
        mediaRepository: any MediaRepository,
        permissionService: any PhotoLibraryPermissionService
    ) {
        self.mediaRepository = mediaRepository
        self.permissionService = permissionService
    }

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

    /// 指定されたメディア配列のキャッシュを開始する
    /// - Parameters:
    ///   - media: キャッシュ対象のメディア配列
    ///   - size: サムネイルサイズ
    /// - Throws: MediaError
    package func startCaching(for media: [Media], size: CGSize) async throws {
        mediaRepository.cacheRepository.startCaching(for: media, size: size)
    }

    /// 指定されたメディア配列のキャッシュを停止する
    /// - Parameters:
    ///   - media: キャッシュ停止対象のメディア配列
    ///   - size: サムネイルサイズ
    /// - Throws: MediaError
    package func stopCaching(for media: [Media], size: CGSize) async throws {
        mediaRepository.cacheRepository.stopCaching(for: media, size: size)
    }

    /// すべてのキャッシュをリセットする
    /// - Throws: MediaError
    package func resetCache() async throws {
        mediaRepository.cacheRepository.resetCache()
    }
}
