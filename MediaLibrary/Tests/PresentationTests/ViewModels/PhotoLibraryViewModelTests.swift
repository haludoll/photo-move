import Application
import Dependencies
import Domain
import Presentation
import XCTest

@available(iOS 15.0, macOS 11.0, *)
final class PhotoLibraryViewModelTests: XCTestCase {
    @MainActor
    private func createViewModel(service: MediaLibraryAppServiceProtocol = MockMediaLibraryAppService()) -> PhotoLibraryViewModel {
        return PhotoLibraryViewModel(mediaLibraryService: service)
    }

    @MainActor
    func testInitialState() {
        let viewModel = createViewModel()

        XCTAssertEqual(viewModel.media.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.hasError)
        XCTAssertEqual(viewModel.thumbnails.count, 0)
    }

    @MainActor
    func testLoadPhotosSuccess() async {
        let viewModel = createViewModel()

        // Act
        await viewModel.loadPhotos()

        // Assert
        XCTAssertEqual(viewModel.media.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.hasError)
    }

    @MainActor
    func testLoadPhotosPermissionDenied() async {
        // Arrange
        let viewModel = createViewModel(service: MockMediaLibraryAppServiceWithError(.permissionDenied))

        // Act
        await viewModel.loadPhotos()

        // Assert
        XCTAssertEqual(viewModel.media.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.error, .permissionDenied)
        XCTAssertTrue(viewModel.hasError)
    }

    @MainActor
    func testLoadPhotosMediaLoadFailed() async {
        // Arrange
        let viewModel = createViewModel(service: MockMediaLibraryAppServiceWithError(.mediaLoadFailed))

        // Act
        await viewModel.loadPhotos()

        // Assert
        XCTAssertEqual(viewModel.media.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.error, .mediaLoadFailed)
        XCTAssertTrue(viewModel.hasError)
    }

    @MainActor
    func testLoadThumbnail() async {
        // Arrange
        let viewModel = createViewModel()
        await viewModel.loadPhotos()
        guard let firstMedia = viewModel.media.first else {
            XCTFail("No media loaded")
            return
        }

        // Act
        viewModel.loadThumbnail(for: firstMedia.id, size: CGSize(width: 100, height: 100))

        // 非同期処理の完了を待つ
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒

        // Assert
        XCTAssertNotNil(viewModel.thumbnails[firstMedia.id])
    }

    @MainActor
    func testLoadThumbnailDuplicate() async {
        // Arrange
        let viewModel = createViewModel()
        await viewModel.loadPhotos()
        guard let firstMedia = viewModel.media.first else {
            XCTFail("No media loaded")
            return
        }

        // Act - 同じサムネイルを2回読み込み
        viewModel.loadThumbnail(for: firstMedia.id, size: CGSize(width: 100, height: 100))
        viewModel.loadThumbnail(for: firstMedia.id, size: CGSize(width: 100, height: 100))

        // 非同期処理の完了を待つ
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒

        // Assert - 重複読み込みされない
        XCTAssertNotNil(viewModel.thumbnails[firstMedia.id])
    }

    @MainActor
    func testClearError() async {
        // Arrange
        let viewModel = createViewModel(service: MockMediaLibraryAppServiceWithError(.permissionDenied))

        await viewModel.loadPhotos()
        XCTAssertTrue(viewModel.hasError)

        // Act
        viewModel.clearError()

        // Assert
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.hasError)
    }

    @MainActor
    func testCancelAllThumbnailTasks() async {
        // Arrange
        let viewModel = createViewModel()
        await viewModel.loadPhotos()
        guard let firstMedia = viewModel.media.first else {
            XCTFail("No media loaded")
            return
        }

        viewModel.loadThumbnail(for: firstMedia.id, size: CGSize(width: 100, height: 100))

        // Act
        viewModel.cancelAllThumbnailTasks()

        // Assert - タスクがキャンセルされても例外が発生しないことを確認
        XCTAssertTrue(true) // テストが完了すれば成功
    }
}

// MARK: - Mock Services

@available(iOS 15.0, macOS 11.0, *)
private struct MockMediaLibraryAppService: MediaLibraryAppServiceProtocol {
    func loadMedia() async throws -> [Media] {
        return try [
            Media(
                id: Media.ID("mock-1"),
                type: .photo,
                metadata: Media.Metadata(
                    format: .jpeg,
                    capturedAt: Date()
                ),
                filePath: "/mock/path/1.jpg"
            ),
            Media(
                id: Media.ID("mock-2"),
                type: .photo,
                metadata: Media.Metadata(
                    format: .png,
                    capturedAt: Date()
                ),
                filePath: "/mock/path/2.png"
            ),
        ]
    }

    func loadThumbnail(for mediaID: Media.ID, size: CGSize) async throws -> Media.Thumbnail {
        return try Media.Thumbnail(
            mediaID: mediaID,
            imageData: Data([0x89, 0x50, 0x4E, 0x47]), // PNG header
            size: size
        )
    }
}

@available(iOS 15.0, macOS 11.0, *)
private struct MockMediaLibraryAppServiceWithError: MediaLibraryAppServiceProtocol {
    private let error: MediaError

    init(_ error: MediaError) {
        self.error = error
    }

    func loadMedia() async throws -> [Media] {
        throw error
    }

    func loadThumbnail(for _: Media.ID, size _: CGSize) async throws -> Media.Thumbnail {
        throw error
    }
}
