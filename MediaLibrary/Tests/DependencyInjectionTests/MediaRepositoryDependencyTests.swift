import CoreGraphics
import Dependencies
import Foundation
import Testing

@testable import DependencyInjection
@testable import Domain

/// MediaRepositoryDependencyのテスト
struct MediaRepositoryDependencyTests {

    @Test("テスト用Mock実装が正しく動作する")
    func testMockImplementation() async throws {
        // Given
        let testResult = await withDependencies { _ in
            // テスト用のMock実装を使用
        } operation: {
            @Dependency(\.mediaRepository) var mediaRepository
            return mediaRepository
        }

        // When
        let media = try await testResult.fetchMedia()

        // Then
        #expect(media.count == 2)
        #expect(media[0].id.value == "mock-1")
        #expect(media[1].id.value == "mock-2")
    }

    @Test("サムネイル取得が正しく動作する")
    func testThumbnailFetch() async throws {
        // Given
        let testResult = await withDependencies { _ in
            // テスト用のMock実装を使用
        } operation: {
            @Dependency(\.mediaRepository) var mediaRepository
            return mediaRepository
        }

        let mediaID = try Media.ID("test-id")
        let size = CGSize(width: 100, height: 100)

        // When
        let thumbnail = try await testResult.fetchThumbnail(for: mediaID, size: size)

        // Then
        #expect(thumbnail.mediaID == mediaID)
        #expect(thumbnail.size == size)
        #expect(!thumbnail.imageData.isEmpty)
    }
}
