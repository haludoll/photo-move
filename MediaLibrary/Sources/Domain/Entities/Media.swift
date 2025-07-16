import Foundation

/// メディア（写真）エンティティ
struct Media: Identifiable {
    /// メディアIDの値オブジェクト
    struct ID: Hashable, Identifiable {
        let value: String
        var id: String { value }

        init(_ value: String) throws {
            guard !value.isEmpty else {
                throw MediaError.invalidMediaID
            }
            self.value = value
        }
    }

    /// メディアメタデータの値オブジェクト
    struct Metadata {
        let format: MediaFormat
        let capturedAt: Date

        init(format: MediaFormat, capturedAt: Date) {
            self.format = format
            self.capturedAt = capturedAt
        }
    }

    /// サムネイル画像の値オブジェクト
    struct Thumbnail {
        let mediaID: ID
        let imageData: Data
        let size: CGSize

        init(mediaID: ID, imageData: Data, size: CGSize) throws {
            guard !imageData.isEmpty else {
                throw MediaError.invalidThumbnailData
            }

            self.mediaID = mediaID
            self.imageData = imageData
            self.size = size
        }
    }

    // MARK: - Properties

    let id: ID
    let type: MediaType
    let metadata: Metadata
    let filePath: String

    // MARK: - Initialization

    init(id: ID, type: MediaType, metadata: Metadata, filePath: String) throws {
        guard !filePath.isEmpty else {
            throw MediaError.invalidFilePath
        }

        self.id = id
        self.type = type
        self.metadata = metadata
        self.filePath = filePath
    }
}
