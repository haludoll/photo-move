import Foundation
import UIKit

/// メディア（写真）エンティティ
package struct Media: Identifiable {
    /// メディアIDの値オブジェクト
    package struct ID: Hashable, Identifiable {
        package let value: String
        package var id: String { value }

        package init(_ value: String) throws {
            guard !value.isEmpty else {
                throw MediaError.invalidMediaID
            }
            self.value = value
        }
    }

    /// メディアメタデータの値オブジェクト
    package struct Metadata {
        package let format: MediaFormat
        package let capturedAt: Date

        package init(format: MediaFormat, capturedAt: Date) {
            self.format = format
            self.capturedAt = capturedAt
        }
    }

    /// サムネイル画像の値オブジェクト
    package struct Thumbnail {
        package let mediaID: ID
        package let image: UIImage
        package let size: CGSize

        package init(mediaID: ID, image: UIImage, size: CGSize) {
            self.mediaID = mediaID
            self.image = image
            self.size = size
        }
    }

    // MARK: - Properties

    package let id: ID
    package let type: MediaType
    package let metadata: Metadata
    package let filePath: String

    // MARK: - Initialization

    package init(id: ID, type: MediaType, metadata: Metadata, filePath: String) throws {
        guard !filePath.isEmpty else {
            throw MediaError.invalidFilePath
        }

        self.id = id
        self.type = type
        self.metadata = metadata
        self.filePath = filePath
    }
}
