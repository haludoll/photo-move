import Foundation
import Testing
@testable import Domain

@Test("Media.Thumbnail - 正常な値で初期化できる")
func thumbnailInitialization() async throws {
    let mediaID = try Media.ID("test-media-id")
    let imageData = "test-image-data".data(using: .utf8)!
    let size = CGSize(width: 150, height: 150)

    let thumbnail = try Media.Thumbnail(mediaID: mediaID, imageData: imageData, size: size)

    #expect(thumbnail.mediaID == mediaID)
    #expect(thumbnail.imageData == imageData)
    #expect(thumbnail.size.width == size.width)
    #expect(thumbnail.size.height == size.height)
}

@Test("Media.Thumbnail - 空のimageDataで初期化すると失敗する")
func thumbnailInitializationWithEmptyImageData() async throws {
    let mediaID = try Media.ID("test-media-id")
    let emptyImageData = Data()
    let size = CGSize(width: 150, height: 150)

    #expect(throws: MediaError.invalidThumbnailData) {
        try Media.Thumbnail(mediaID: mediaID, imageData: emptyImageData, size: size)
    }
}
