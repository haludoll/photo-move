import XCTest
import Foundation
@testable import Domain

/// MediaRepositoryの仕様を定義するテスト
final class MediaRepositoryTests: XCTestCase {
    
    // MARK: - テスト用のMock実装
    
    private final class MockMediaRepository: MediaRepository {
        var fetchMediaResult: Result<[Media], MediaError> = .success([])
        var fetchThumbnailResult: Result<Media.Thumbnail, MediaError> = .failure(.mediaNotFound)
        
        func fetchMedia() async throws -> [Media] {
            switch fetchMediaResult {
            case .success(let media):
                return media
            case .failure(let error):
                throw error
            }
        }
        
        func fetchThumbnail(for mediaID: Media.ID, size: CGSize) async throws -> Media.Thumbnail {
            switch fetchThumbnailResult {
            case .success(let thumbnail):
                return thumbnail
            case .failure(let error):
                throw error
            }
        }
    }
    
    // MARK: - テストケース
    
    func testFetchMedia_成功時はメディア配列を返す() async throws {
        // Given
        let repository = MockMediaRepository()
        let expectedMedia = [
            try createTestMedia(id: "1"),
            try createTestMedia(id: "2")
        ]
        repository.fetchMediaResult = .success(expectedMedia)
        
        // When
        let result = try await repository.fetchMedia()
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id.value, "1")
        XCTAssertEqual(result[1].id.value, "2")
    }
    
    func testFetchMedia_失敗時はエラーを投げる() async {
        // Given
        let repository = MockMediaRepository()
        repository.fetchMediaResult = .failure(.permissionDenied)
        
        // When & Then
        do {
            _ = try await repository.fetchMedia()
            XCTFail("エラーが投げられるべき")
        } catch let error as MediaError {
            XCTAssertEqual(error, .permissionDenied)
        } catch {
            XCTFail("MediaErrorが投げられるべき")
        }
    }
    
    func testFetchThumbnail_成功時はサムネイルを返す() async throws {
        // Given
        let repository = MockMediaRepository()
        let mediaID = try Media.ID("test-id")
        let expectedThumbnail = try createTestThumbnail(mediaID: mediaID)
        repository.fetchThumbnailResult = .success(expectedThumbnail)
        
        // When
        let result = try await repository.fetchThumbnail(for: mediaID, size: CGSize(width: 100, height: 100))
        
        // Then
        XCTAssertEqual(result.mediaID, mediaID)
        XCTAssertEqual(result.size.width, 100)
        XCTAssertEqual(result.size.height, 100)
    }
    
    func testFetchThumbnail_失敗時はエラーを投げる() async throws {
        // Given
        let repository = MockMediaRepository()
        let mediaID = try Media.ID("test-id")
        repository.fetchThumbnailResult = .failure(.mediaNotFound)
        
        // When & Then
        do {
            _ = try await repository.fetchThumbnail(for: mediaID, size: CGSize(width: 100, height: 100))
            XCTFail("エラーが投げられるべき")
        } catch let error as MediaError {
            XCTAssertEqual(error, .mediaNotFound)
        } catch {
            XCTFail("MediaErrorが投げられるべき")
        }
    }
    
    // MARK: - ヘルパーメソッド
    
    private func createTestMedia(id: String) throws -> Media {
        return try Media(
            id: try Media.ID(id),
            type: .photo,
            metadata: Media.Metadata(
                format: .jpeg,
                capturedAt: Date()
            ),
            filePath: "/path/to/media/\(id).jpg"
        )
    }
    
    private func createTestThumbnail(mediaID: Media.ID) throws -> Media.Thumbnail {
        return try Media.Thumbnail(
            mediaID: mediaID,
            imageData: Data([0x89, 0x50, 0x4E, 0x47]), // PNG header
            size: CGSize(width: 100, height: 100)
        )
    }
}