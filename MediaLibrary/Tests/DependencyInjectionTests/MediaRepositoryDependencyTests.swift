import XCTest
import Dependencies
@testable import DependencyInjection
@testable import Domain

/// MediaRepositoryDependencyのテスト
final class MediaRepositoryDependencyTests: XCTestCase {
    
    func testMediaRepositoryDependency_テスト用Mock実装が正しく動作する() async throws {
        // Given
        let testResult = await withDependencies {
            // テスト用のMock実装を使用
        } operation: {
            @Dependency(\.mediaRepository) var mediaRepository
            return mediaRepository
        }
        
        // When
        let media = try await testResult.fetchMedia()
        
        // Then
        XCTAssertEqual(media.count, 2)
        XCTAssertEqual(media[0].id.value, "mock-1")
        XCTAssertEqual(media[1].id.value, "mock-2")
    }
    
    func testMediaRepositoryDependency_サムネイル取得が正しく動作する() async throws {
        // Given
        let testResult = await withDependencies {
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
        XCTAssertEqual(thumbnail.mediaID, mediaID)
        XCTAssertEqual(thumbnail.size, size)
        XCTAssertFalse(thumbnail.imageData.isEmpty)
    }
}