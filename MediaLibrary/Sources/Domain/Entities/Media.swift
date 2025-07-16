import Foundation

/// メディア（写真）エンティティ
public struct Media: Identifiable {
    /// メディアIDの値オブジェクト
    public struct ID: Hashable, Identifiable {
        public let value: String
        public var id: String { value }

        public init(_ value: String) throws {
            guard !value.isEmpty else {
                throw MediaError.invalidMediaID
            }
            self.value = value
        }
    }

    /// メディアメタデータの値オブジェクト
    public struct Metadata {
        public let format: MediaFormat
        public let capturedAt: Date

        public init(format: MediaFormat, capturedAt: Date) {
            self.format = format
            self.capturedAt = capturedAt
        }
    }

    /// サムネイル画像の値オブジェクト
    public struct Thumbnail {
        public let mediaID: ID
        public let imageData: Data
        public let size: CGSize

        public init(mediaID: ID, imageData: Data, size: CGSize) throws {
            guard !imageData.isEmpty else {
                throw MediaError.invalidThumbnailData
            }

            self.mediaID = mediaID
            self.imageData = imageData
            self.size = size
        }
    }

    // MARK: - Properties

    public let id: ID
    public let type: MediaType
    public let metadata: Metadata
    public let filePath: String

    // MARK: - Initialization

    public init(id: ID, type: MediaType, metadata: Metadata, filePath: String) throws {
        guard !filePath.isEmpty else {
            throw MediaError.invalidFilePath
        }

        self.id = id
        self.type = type
        self.metadata = metadata
        self.filePath = filePath
    }
}
