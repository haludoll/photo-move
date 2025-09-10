import Foundation
import UIKit

/// メディア（写真）エンティティ
package struct Media: Identifiable, Hashable {
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
        package let imageData: Data
        package let size: CGSize

        package init(mediaID: ID, imageData: Data, size: CGSize) throws {
            guard !imageData.isEmpty else {
                throw MediaError.invalidThumbnailData
            }
            
            self.mediaID = mediaID
            self.imageData = imageData
            self.size = size
        }
        
        /// UIImageからThumbnailを作成する便利メソッド（UI層で使用）
        package static func from(mediaID: ID, image: UIImage, size: CGSize) throws -> Thumbnail {
            guard let imageData = image.pngData() else {
                throw MediaError.invalidThumbnailData
            }
            return try Thumbnail(mediaID: mediaID, imageData: imageData, size: size)
        }
        
        /// imageDataからUIImageを作成する便利メソッド（UI層で使用）
        package var image: UIImage? {
            return UIImage(data: imageData)
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

    // MARK: - Hashable

    package func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    package static func == (lhs: Media, rhs: Media) -> Bool {
        return lhs.id == rhs.id
    }
}
