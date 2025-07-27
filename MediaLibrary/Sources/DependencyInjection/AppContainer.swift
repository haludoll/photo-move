import Application
import Domain
import Foundation
import Infrastructure

/// アプリケーション全体の依存関係を管理する構造体
/// Composition Rootパターンを実装
package enum AppDependencies {
    // MARK: - Infrastructure Layer

    /// MediaRepository の実装
    package static let mediaRepository: any MediaRepository = MediaRepositoryImpl()

    /// PhotoLibraryPermissionService の実装
    package static let photoLibraryPermissionService: any PhotoLibraryPermissionService =
        PhotoLibraryPermissionServiceImpl()

    // MARK: - Application Layer

    /// MediaLibraryAppService の実装
    package static let mediaLibraryAppService: any MediaLibraryAppService = MediaLibraryAppServiceImpl(
        mediaRepository: mediaRepository,
        permissionService: photoLibraryPermissionService
    )
}

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
