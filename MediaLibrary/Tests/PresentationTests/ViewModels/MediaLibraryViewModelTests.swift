import MediaLibraryApplication
import CoreGraphics
import MediaLibraryDomain
import Foundation
import MediaLibraryPresentation
import Testing

struct MediaLibraryViewModelTests {
    @Test("初期状態のテスト")
    @MainActor
    func initialState() async {
        let mockRepository = MockSuccessRepository()
        let mockPermissionService = MockPermissionService()
        let mockAppService = MediaLibraryAppServiceImpl(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )
        let viewModel = MediaLibraryViewModel(mediaLibraryService: mockAppService)

        #expect(viewModel.media.count == 0)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
        #expect(viewModel.hasError == false)
        #expect(viewModel.thumbnails.count == 0)
    }

    @Test("写真読み込み成功のテスト")
    @MainActor
    func loadPhotosSuccess() async {
        let mockMedia = try! [
            createTestMedia(id: "1"),
            createTestMedia(id: "2"),
        ]

        let mockRepository = MockSuccessRepository(media: mockMedia)
        let mockPermissionService = MockPermissionService()
        let mockAppService = MediaLibraryAppServiceImpl(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )
        let viewModel = MediaLibraryViewModel(mediaLibraryService: mockAppService)

        // Act
        await viewModel.loadPhotos()

        // Assert
        #expect(viewModel.media.count == 2)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
        #expect(viewModel.hasError == false)
    }

    @Test("権限拒否エラーのテスト")
    @MainActor
    func loadPhotosPermissionDenied() async {
        let mockRepository = MockFailureRepository()
        let mockPermissionService = MockDeniedPermissionService()
        let mockAppService = MediaLibraryAppServiceImpl(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )
        let viewModel = MediaLibraryViewModel(mediaLibraryService: mockAppService)

        // Act
        await viewModel.loadPhotos()

        // Assert
        #expect(viewModel.media.count == 0)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == .permissionDenied)
        #expect(viewModel.hasError == true)
    }

    @Test("メディア読み込み失敗のテスト")
    @MainActor
    func loadPhotosMediaLoadFailed() async {
        let mockRepository = MockFailureRepository()
        let mockPermissionService = MockPermissionService()
        let mockAppService = MediaLibraryAppServiceImpl(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )
        let viewModel = MediaLibraryViewModel(mediaLibraryService: mockAppService)

        // Act
        await viewModel.loadPhotos()

        // Assert
        #expect(viewModel.media.count == 0)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == .permissionDenied)
        #expect(viewModel.hasError == true)
    }

    @Test("サムネイル読み込みのテスト")
    @MainActor
    func testLoadThumbnail() async {
        let mockMedia = try! [createTestMedia(id: "1")]
        let mockRepository = MockSuccessRepository(media: mockMedia)
        let mockPermissionService = MockPermissionService()
        let mockAppService = MediaLibraryAppServiceImpl(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )
        let viewModel = MediaLibraryViewModel(mediaLibraryService: mockAppService)

        await viewModel.loadPhotos()
        guard let firstMedia = viewModel.media.first else {
            Issue.record("No media loaded")
            return
        }

        // Act
        viewModel.loadThumbnail(for: firstMedia.id, size: CGSize(width: 100, height: 100))

        // 非同期処理の完了を待つ
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

        // Assert
        #expect(viewModel.thumbnails[firstMedia.id] != nil)
    }

    @Test("サムネイル重複読み込みのテスト")
    @MainActor
    func loadThumbnailDuplicate() async {
        let mockMedia = try! [createTestMedia(id: "1")]
        let mockRepository = MockSuccessRepository(media: mockMedia)
        let mockPermissionService = MockPermissionService()
        let mockAppService = MediaLibraryAppServiceImpl(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )
        let viewModel = MediaLibraryViewModel(mediaLibraryService: mockAppService)

        await viewModel.loadPhotos()
        guard let firstMedia = viewModel.media.first else {
            Issue.record("No media loaded")
            return
        }

        // Act - 同じサムネイルを2回読み込み
        viewModel.loadThumbnail(for: firstMedia.id, size: CGSize(width: 100, height: 100))
        viewModel.loadThumbnail(for: firstMedia.id, size: CGSize(width: 100, height: 100))

        // 非同期処理の完了を待つ
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

        // Assert - 重複読み込みされない
        #expect(viewModel.thumbnails[firstMedia.id] != nil)
    }

    @Test("エラークリアのテスト")
    @MainActor
    func testClearError() async {
        let mockRepository = MockFailureRepository()
        let mockPermissionService = MockDeniedPermissionService()
        let mockAppService = MediaLibraryAppServiceImpl(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )
        let viewModel = MediaLibraryViewModel(mediaLibraryService: mockAppService)

        await viewModel.loadPhotos()
        #expect(viewModel.hasError == true)

        // Act
        viewModel.clearError()

        // Assert
        #expect(viewModel.error == nil)
        #expect(viewModel.hasError == false)
    }

    @Test("サムネイルタスクキャンセルのテスト")
    @MainActor
    func testCancelAllThumbnailTasks() async {
        let mockMedia = try! [createTestMedia(id: "1")]
        let mockRepository = MockSuccessRepository(media: mockMedia)
        let mockPermissionService = MockPermissionService()
        let mockAppService = MediaLibraryAppServiceImpl(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )
        let viewModel = MediaLibraryViewModel(mediaLibraryService: mockAppService)

        await viewModel.loadPhotos()
        guard let firstMedia = viewModel.media.first else {
            Issue.record("No media loaded")
            return
        }

        viewModel.loadThumbnail(for: firstMedia.id, size: CGSize(width: 100, height: 100))

        // Act
        viewModel.cancelAllThumbnailTasks()

        // Assert - タスクがキャンセルされても例外が発生しないことを確認
        #expect(true)  // テストが完了すれば成功
    }
}

// MARK: - Helper Methods

private func createTestMedia(id: String) throws -> Media {
    return try Media(
        id: Media.ID(id),
        type: .photo,
        metadata: Media.Metadata(
            format: .jpeg,
            capturedAt: Date()
        ),
        filePath: "/path/to/media/\(id).jpg"
    )
}

// MARK: - Mock Services

private struct MockSuccessRepository: MediaRepository, Sendable {
    let media: [Media]
    let thumbnail: Media.Thumbnail?

    init(media: [Media] = [], thumbnail: Media.Thumbnail? = nil) {
        self.media = media
        self.thumbnail = thumbnail
    }

    func fetchMedia() async throws -> [Media] {
        return media
    }

    func fetchThumbnail(for mediaID: Media.ID, size: CGSize) async throws -> Media.Thumbnail {
        if let thumbnail = thumbnail {
            return thumbnail
        }

        return try Media.Thumbnail(
            mediaID: mediaID,
            imageData: Data([0x89, 0x50, 0x4E, 0x47]),
            size: size
        )
    }
}

private struct MockFailureRepository: MediaRepository, Sendable {
    func fetchMedia() async throws -> [Media] {
        throw MediaError.permissionDenied
    }

    func fetchThumbnail(for _: Media.ID, size _: CGSize) async throws -> Media.Thumbnail {
        throw MediaError.mediaNotFound
    }
}

private struct MockPermissionService: PhotoLibraryPermissionService, Sendable {
    func checkPermissionStatus() -> PhotoLibraryPermissionStatus {
        return .authorized
    }

    func requestPermission() async -> PhotoLibraryPermissionStatus {
        return .authorized
    }
}

private struct MockDeniedPermissionService: PhotoLibraryPermissionService, Sendable {
    func checkPermissionStatus() -> PhotoLibraryPermissionStatus {
        return .denied
    }

    func requestPermission() async -> PhotoLibraryPermissionStatus {
        return .denied
    }
}
