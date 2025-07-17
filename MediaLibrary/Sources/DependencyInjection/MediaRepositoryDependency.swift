import Dependencies
import Domain
import Foundation
import Infrastructure

/// MediaRepositoryの依存関係定義
extension DependencyValues {
    /// メディアリポジトリの依存関係
    package var mediaRepository: MediaRepository {
        get { self[MediaRepositoryKey.self] }
        set { self[MediaRepositoryKey.self] = newValue }
    }
}

/// MediaRepositoryのDependencyKey
private enum MediaRepositoryKey: DependencyKey {
    static let liveValue: MediaRepository = {
        #if canImport(UIKit)
            return PhotoKitMediaRepository()
        #else
            fatalError("PhotoKitMediaRepository requires UIKit (iOS only)")
        #endif
    }()

    static let testValue: MediaRepository = MockMediaRepository()
}

/// テスト用のMockMediaRepository
private struct MockMediaRepository: MediaRepository, Sendable {
    func fetchMedia() async throws -> [Media] {
        // テスト用のダミーデータ
        return [
            try Media(
                id: try Media.ID("mock-1"),
                type: .photo,
                metadata: Media.Metadata(
                    format: .jpeg,
                    capturedAt: Date()
                ),
                filePath: "/mock/path/1.jpg"
            ),
            try Media(
                id: try Media.ID("mock-2"),
                type: .photo,
                metadata: Media.Metadata(
                    format: .png,
                    capturedAt: Date()
                ),
                filePath: "/mock/path/2.png"
            ),
        ]
    }

    func fetchThumbnail(for mediaID: Media.ID, size: CGSize) async throws -> Media.Thumbnail {
        // テスト用のダミーサムネイル
        return try Media.Thumbnail(
            mediaID: mediaID,
            imageData: Data([0x89, 0x50, 0x4E, 0x47]),  // PNG header
            size: size
        )
    }
}
