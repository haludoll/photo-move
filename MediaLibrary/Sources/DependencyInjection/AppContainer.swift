import Foundation
import MediaLibraryApplication
import MediaLibraryDomain
import MediaLibraryInfrastructure
import SwiftUI

/// アプリケーション全体の依存関係を管理する構造体
/// Composition Rootパターンを実装
package enum AppDependencies {
    // MARK: - Infrastructure Layer

    /// MediaCacheRepository の実装
    package static let mediaCacheRepository: any MediaCacheRepository = MediaCacheRepositoryImpl()

    /// MediaRepository の実装
    package static let mediaRepository: any MediaRepository = {
        #if DEBUG
            if EnvironmentUtils.isRunningInPreview {
                return PreviewDependencies.mediaRepository
            }
        #endif
        return MediaRepositoryImpl(cacheRepository: mediaCacheRepository)
    }()

    /// PhotoLibraryPermissionService の実装
    package static let photoLibraryPermissionService: any PhotoLibraryPermissionService = {
        #if DEBUG
            if EnvironmentUtils.isRunningInPreview {
                return PreviewDependencies.photoLibraryPermissionService
            }
        #endif
        return PhotoLibraryPermissionServiceImpl()
    }()

    // MARK: - Application Layer

    /// MediaLibraryAppService の実装
    package static let mediaLibraryAppService: any MediaLibraryAppService = MediaLibraryAppServiceImpl(
        mediaRepository: mediaRepository,
        permissionService: photoLibraryPermissionService
    )
}

// MARK: - Preview Support

#if DEBUG
    /// プレビュー用のモックキャッシュリポジトリ
    fileprivate struct MockMediaCacheRepository: MediaCacheRepository {
        func startCaching(for _: [Media], size _: CGSize) {}
        func stopCaching(for _: [Media], size _: CGSize) {}
        func resetCache() {}
    }

    /// プレビュー用のモックリポジトリ
    fileprivate struct MockMediaRepository: MediaRepository {
        let cacheRepository: MediaCacheRepository = MockMediaCacheRepository()
        func fetchMedia() async throws -> [Media] {
            return try [
                Media(
                    id: Media.ID("1"),
                    type: .photo,
                    metadata: Media.Metadata(format: .jpeg, capturedAt: Date()),
                    filePath: "dummy1.jpg"
                ),
                Media(
                    id: Media.ID("2"),
                    type: .photo,
                    metadata: Media.Metadata(format: .jpeg, capturedAt: Date()),
                    filePath: "dummy2.jpg"
                ),
                Media(
                    id: Media.ID("3"),
                    type: .photo,
                    metadata: Media.Metadata(format: .png, capturedAt: Date()),
                    filePath: "dummy3.png"
                ),
            ]
        }

        func fetchThumbnail(for mediaID: Media.ID, size: CGSize) async throws -> Media.Thumbnail {
            let systemImages = ["photo.fill", "camera.fill", "video.fill", "heart.fill", "star.fill"]
            let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPink, .systemPurple]

            let index = abs(mediaID.value.hashValue) % systemImages.count
            let imageName = systemImages[index]
            let color = colors[index]

            let config = UIImage.SymbolConfiguration(pointSize: min(size.width, size.height) * 0.6, weight: .medium)
            let image = UIImage(systemName: imageName, withConfiguration: config)?.withTintColor(color, renderingMode: .alwaysOriginal)

            let data = image?.jpegData(compressionQuality: 0.8) ?? UIImage().jpegData(compressionQuality: 0.8)!
            return try Media.Thumbnail(
                mediaID: mediaID,
                imageData: data,
                size: size
            )
        }
    }

    /// プレビュー用のモック権限サービス
    fileprivate struct MockPhotoLibraryPermissionService: PhotoLibraryPermissionService {
        func checkPermissionStatus() -> PhotoLibraryPermissionStatus {
            return .authorized
        }

        func requestPermission() async -> PhotoLibraryPermissionStatus {
            return .authorized
        }
    }

    /// プレビュー用の依存関係を管理する構造体
    package enum PreviewDependencies {
        package static let mediaRepository: any MediaRepository = MockMediaRepository()
        package static let photoLibraryPermissionService: any PhotoLibraryPermissionService = MockPhotoLibraryPermissionService()
    }
#endif

// MARK: - Test Support

/// テスト用の依存関係を管理する構造体
package struct TestDependencies {
    // MARK: - Mock Dependencies

    package let mediaRepository: any MediaRepository
    package let photoLibraryPermissionService: any PhotoLibraryPermissionService

    // MARK: - Computed Properties

    /// MediaLibraryAppService のテスト実装
    package var mediaLibraryAppService: any MediaLibraryAppService {
        MediaLibraryAppServiceImpl(
            mediaRepository: mediaRepository,
            permissionService: photoLibraryPermissionService
        )
    }

    // MARK: - Initialization

    package init(
        mediaRepository: any MediaRepository,
        permissionService: any PhotoLibraryPermissionService
    ) {
        self.mediaRepository = mediaRepository
        photoLibraryPermissionService = permissionService
    }
}
