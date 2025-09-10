import Foundation
import UIKit
import MediaLibraryDomain

/// UIImageとMedia.Thumbnailの変換を行うユーティリティ
enum ThumbnailConverter {
    /// UIImageからMedia.Thumbnailを作成
    static func createThumbnail(from image: UIImage, mediaID: Media.ID, size: CGSize) throws -> Media.Thumbnail {
        guard let imageData = image.pngData() else {
            throw MediaError.invalidThumbnailData
        }
        return try Media.Thumbnail(mediaID: mediaID, imageData: imageData, size: size)
    }
    
    /// Media.ThumbnailからUIImageを作成
    static func createImage(from thumbnail: Media.Thumbnail) -> UIImage? {
        return UIImage(data: thumbnail.imageData)
    }
}