import CoreGraphics
import Foundation
import Testing

@testable import Application
@testable import Domain

/// MediaLibraryAppServiceのテスト
struct MediaLibraryAppServiceTests {
    @Test("メディア一覧取得が成功する")
    func loadMediaSuccess() async throws {
        // Given
        let mockMedia = try [
            createTestMedia(id: "1"),
            createTestMedia(id: "2"),
        ]

        let mockRepository = MockSuccessRepository(media: mockMedia)
        let mockPermissionService = MockPermissionService()
        let service = MediaLibraryAppService(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )

        // When
        let result = try await service.loadMedia()

        // Then
        #expect(result.count == 2)
        #expect(result[0].id.value == "1")
        #expect(result[1].id.value == "2")
    }

    @Test("メディア一覧取得が失敗する")
    func loadMediaFailure() async throws {
        let mockRepository = MockFailureRepository()
        let mockPermissionService = MockPermissionDeniedService()
        let service = MediaLibraryAppService(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )

        // When & Then
        await #expect(throws: MediaError.permissionDenied) {
            try await service.loadMedia()
        }
    }

    @Test("サムネイル取得が成功する")
    func loadThumbnailSuccess() async throws {
        // Given
        let mediaID = try Media.ID("test-id")
        let size = CGSize(width: 100, height: 100)
        let expectedThumbnail = try Media.Thumbnail(
            mediaID: mediaID,
            imageData: Data([0x89, 0x50, 0x4E, 0x47]),
            size: size
        )

        let mockRepository = MockSuccessRepository(thumbnail: expectedThumbnail)
        let mockPermissionService = MockPermissionService()
        let service = MediaLibraryAppService(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )

        // When
        let thumbnail = try await service.loadThumbnail(for: mediaID, size: size)

        // Then
        #expect(thumbnail.mediaID == mediaID)
        #expect(thumbnail.size == size)
        #expect(thumbnail.imageData == expectedThumbnail.imageData)
    }

    @Test("サムネイル取得が失敗する")
    func loadThumbnailFailure() async throws {
        // Given
        let mediaID = try Media.ID("test-id")
        let size = CGSize(width: 100, height: 100)

        let mockRepository = MockFailureRepository()
        let mockPermissionService = MockPermissionService()
        let service = MediaLibraryAppService(
            mediaRepository: mockRepository,
            permissionService: mockPermissionService
        )

        // When & Then
        await #expect(throws: MediaError.mediaNotFound) {
            try await service.loadThumbnail(for: mediaID, size: size)
        }
    }

    // MARK: - ヘルパーメソッド

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
}

// MARK: - Mock Repository

/// 成功用のMockRepository
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

/// 失敗用のMockRepository
private struct MockFailureRepository: MediaRepository, Sendable {
    func fetchMedia() async throws -> [Media] {
        throw MediaError.permissionDenied
    }

    func fetchThumbnail(for _: Media.ID, size _: CGSize) async throws -> Media.Thumbnail {
        throw MediaError.mediaNotFound
    }
}

// MARK: - Mock Permission Service

/// 成功用のMockPermissionService
private struct MockPermissionService: PhotoLibraryPermissionService, Sendable {
    func checkPermissionStatus() -> PhotoLibraryPermissionStatus {
        return .authorized
    }

    func requestPermission() async -> PhotoLibraryPermissionStatus {
        return .authorized
    }
}

/// 権限拒否用のMockPermissionService
private struct MockPermissionDeniedService: PhotoLibraryPermissionService, Sendable {
    func checkPermissionStatus() -> PhotoLibraryPermissionStatus {
        return .denied
    }

    func requestPermission() async -> PhotoLibraryPermissionStatus {
        return .denied
    }
}
