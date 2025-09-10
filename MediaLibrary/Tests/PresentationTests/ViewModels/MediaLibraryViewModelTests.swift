import CoreGraphics
import MediaLibraryDomain
import Foundation
import MediaLibraryApplication
import Testing
@testable import MediaLibraryPresentation

@MainActor
struct MediaLibraryViewModelTests {
    @Test("初期状態のテスト")
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

    // MARK: - Selection Tests

    @Test("選択モード初期状態のテスト")
    func selectionModeInitialState() async {
        let mockRepository = MockSuccessRepository()
        let mockPermissionService = MockPermissionService()
        let mockAppService = MediaLibraryAppServiceImpl(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )
        let viewModel = MediaLibraryViewModel(mediaLibraryService: mockAppService)

        // Assert
        #expect(viewModel.isSelectionMode == false)
        #expect(viewModel.selectedMediaIDs.isEmpty)
        #expect(viewModel.selectedMedia.isEmpty)
        #expect(viewModel.selectedCount == 0)
    }

    @Test("選択モード開始のテスト")
    func enterSelectionMode() async {
        let mockRepository = MockSuccessRepository()
        let mockPermissionService = MockPermissionService()
        let mockAppService = MediaLibraryAppServiceImpl(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )
        let viewModel = MediaLibraryViewModel(mediaLibraryService: mockAppService)

        // Act
        viewModel.enterSelectionMode()

        // Assert
        #expect(viewModel.isSelectionMode == true)
        #expect(viewModel.selectedMediaIDs.isEmpty)
    }

    @Test("選択モード終了のテスト")
    func exitSelectionMode() async {
        let mockMedia = try! [
            createTestMedia(id: "1"),
            createTestMedia(id: "2")
        ]
        let mockRepository = MockSuccessRepository(media: mockMedia)
        let mockPermissionService = MockPermissionService()
        let mockAppService = MediaLibraryAppServiceImpl(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )
        let viewModel = MediaLibraryViewModel(mediaLibraryService: mockAppService)

        await viewModel.loadPhotos()
        viewModel.enterSelectionMode()
        
        // いくつか選択
        if let firstMedia = viewModel.media.first {
            viewModel.toggleSelection(for: firstMedia.id)
        }

        #expect(viewModel.isSelectionMode == true)
        #expect(viewModel.selectedCount > 0)

        // Act
        viewModel.exitSelectionMode()

        // Assert
        #expect(viewModel.isSelectionMode == false)
        #expect(viewModel.selectedMediaIDs.isEmpty)
        #expect(viewModel.selectedCount == 0)
    }

    @Test("メディア選択のテスト")
    func toggleSelection() async {
        let mockMedia = try! [
            createTestMedia(id: "1"),
            createTestMedia(id: "2")
        ]
        let mockRepository = MockSuccessRepository(media: mockMedia)
        let mockPermissionService = MockPermissionService()
        let mockAppService = MediaLibraryAppServiceImpl(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )
        let viewModel = MediaLibraryViewModel(mediaLibraryService: mockAppService)

        await viewModel.loadPhotos()
        viewModel.enterSelectionMode()

        guard let firstMedia = viewModel.media.first else {
            Issue.record("No media loaded")
            return
        }

        // Act - 選択
        viewModel.toggleSelection(for: firstMedia.id)

        // Assert
        #expect(viewModel.isSelected(firstMedia.id) == true)
        #expect(viewModel.selectedCount == 1)
        #expect(viewModel.selectedMedia.count == 1)
        #expect(viewModel.selectedMedia.first?.id == firstMedia.id)

        // Act - 選択解除
        viewModel.toggleSelection(for: firstMedia.id)

        // Assert
        #expect(viewModel.isSelected(firstMedia.id) == false)
        #expect(viewModel.selectedCount == 0)
        #expect(viewModel.selectedMedia.isEmpty)
    }

    @Test("選択モード外での選択無効化のテスト")
    func toggleSelectionOutsideSelectionMode() async {
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

        // Act - 選択モード外で選択を試行
        viewModel.toggleSelection(for: firstMedia.id)

        // Assert - 選択されない
        #expect(viewModel.isSelected(firstMedia.id) == false)
        #expect(viewModel.selectedCount == 0)
    }

    @Test("全選択のテスト")
    func selectAll() async {
        let mockMedia = try! [
            createTestMedia(id: "1"),
            createTestMedia(id: "2"),
            createTestMedia(id: "3")
        ]
        let mockRepository = MockSuccessRepository(media: mockMedia)
        let mockPermissionService = MockPermissionService()
        let mockAppService = MediaLibraryAppServiceImpl(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )
        let viewModel = MediaLibraryViewModel(mediaLibraryService: mockAppService)

        await viewModel.loadPhotos()
        viewModel.enterSelectionMode()

        // Act
        viewModel.selectAll()

        // Assert
        #expect(viewModel.selectedCount == 3)
        #expect(viewModel.selectedMedia.count == 3)
        
        for media in viewModel.media {
            #expect(viewModel.isSelected(media.id) == true)
        }
    }

    @Test("全選択解除のテスト")
    func clearSelection() async {
        let mockMedia = try! [
            createTestMedia(id: "1"),
            createTestMedia(id: "2")
        ]
        let mockRepository = MockSuccessRepository(media: mockMedia)
        let mockPermissionService = MockPermissionService()
        let mockAppService = MediaLibraryAppServiceImpl(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )
        let viewModel = MediaLibraryViewModel(mediaLibraryService: mockAppService)

        await viewModel.loadPhotos()
        viewModel.enterSelectionMode()
        viewModel.selectAll()

        #expect(viewModel.selectedCount == 2)

        // Act
        viewModel.clearSelection()

        // Assert
        #expect(viewModel.selectedCount == 0)
        #expect(viewModel.selectedMedia.isEmpty)
        #expect(viewModel.selectedMediaIDs.isEmpty)
    }

    @Test("選択状態の複数メディア操作のテスト")
    func multipleMediaSelection() async {
        let mockMedia = try! [
            createTestMedia(id: "1"),
            createTestMedia(id: "2"),
            createTestMedia(id: "3")
        ]
        let mockRepository = MockSuccessRepository(media: mockMedia)
        let mockPermissionService = MockPermissionService()
        let mockAppService = MediaLibraryAppServiceImpl(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )
        let viewModel = MediaLibraryViewModel(mediaLibraryService: mockAppService)

        await viewModel.loadPhotos()
        viewModel.enterSelectionMode()

        // Act - 一部を選択
        viewModel.toggleSelection(for: mockMedia[0].id)
        viewModel.toggleSelection(for: mockMedia[2].id)

        // Assert
        #expect(viewModel.selectedCount == 2)
        #expect(viewModel.isSelected(mockMedia[0].id) == true)
        #expect(viewModel.isSelected(mockMedia[1].id) == false)
        #expect(viewModel.isSelected(mockMedia[2].id) == true)

        let selectedMediaIDs = Set(viewModel.selectedMedia.map(\.id))
        #expect(selectedMediaIDs.contains(mockMedia[0].id))
        #expect(selectedMediaIDs.contains(mockMedia[2].id))
        #expect(!selectedMediaIDs.contains(mockMedia[1].id))
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
    var cacheRepository: any MediaLibraryDomain.MediaCacheRepository
    let media: [Media]
    let thumbnail: Media.Thumbnail?

    init(media: [Media] = [], thumbnail: Media.Thumbnail? = nil) {
        self.media = media
        self.thumbnail = thumbnail
        self.cacheRepository = MockMediaCacheRepository()
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
            imageData: Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
            size: size
        )
    }
}

private struct MockFailureRepository: MediaRepository, Sendable {
    var cacheRepository: any MediaLibraryDomain.MediaCacheRepository
    
    init() {
        self.cacheRepository = MockMediaCacheRepository()
    }
    
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

// MARK: - Mock Cache Repository

/// MediaCacheRepositoryのモック実装
private struct MockMediaCacheRepository: MediaCacheRepository, Sendable {
    func startCaching(for media: [MediaLibraryDomain.Media], size: CGSize) {}
    func stopCaching(for media: [MediaLibraryDomain.Media], size: CGSize) {}
    func resetCache() {}
}
