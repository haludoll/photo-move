import Foundation
import MediaLibraryApplication
import MediaLibraryDomain
import MediaLibraryInfrastructure
import SwiftUI
import UIKit

/// アプリケーション全体の依存関係を管理する構造体
/// Composition Rootパターンを実装
package enum AppDependencies {
    // MARK: - Infrastructure Layer

    /// MediaRepository の実装
    package static let mediaRepository: any MediaRepository = {
        #if DEBUG
            if EnvironmentUtils.isRunningInPreview {
                return PreviewDependencies.mediaRepository
            }
        #endif
        return MediaRepositoryImpl()
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
    /// プレビュー用のモックリポジトリ
    fileprivate struct MockMediaRepository: MediaRepository {
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
            // モックデータとして1x1の透明PNG画像を生成
            let mockImageData = Data([
                0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
                0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
                0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
                0x0B, 0x49, 0x44, 0x41, 0x54, 0x08, 0x57, 0x63, 0x60, 0x00, 0x02, 0x00,
                0x00, 0x05, 0x00, 0x01, 0xE2, 0x26, 0x05, 0x9B, 0x00, 0x00, 0x00, 0x00,
                0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
            ])
            
            return try Media.Thumbnail(
                mediaID: mediaID,
                imageData: mockImageData,
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
