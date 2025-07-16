import Foundation
import Testing
@testable import Domain

@Test("Media - 正常な値で初期化できる")
func mediaInitialization() async throws {
    let mediaID = try Media.ID("test-media-id")
    let mediaType = MediaType.photo
    let metadata = Media.Metadata(format: .jpeg, capturedAt: Date())
    let filePath = "/path/to/media.jpg"

    let media = try Media(
        id: mediaID,
        type: mediaType,
        metadata: metadata,
        filePath: filePath)

    #expect(media.id == mediaID)
    #expect(media.type == mediaType)
    #expect(media.metadata.format == metadata.format)
    #expect(media.metadata.capturedAt == metadata.capturedAt)
    #expect(media.filePath == filePath)
}

@Test("Media - 空のfilePathで初期化すると失敗する")
func mediaInitializationWithEmptyFilePath() async throws {
    let mediaID = try Media.ID("test-media-id")
    let mediaType = MediaType.photo
    let metadata = Media.Metadata(format: .jpeg, capturedAt: Date())
    let emptyFilePath = ""

    #expect(throws: MediaError.invalidFilePath) {
        try Media(
            id: mediaID,
            type: mediaType,
            metadata: metadata,
            filePath: emptyFilePath)
    }
}

@Test("Media - Identifiable protocol準拠")
func mediaIdentifiable() async throws {
    let mediaID = try Media.ID("test-media-id")
    let mediaType = MediaType.photo
    let metadata = Media.Metadata(format: .jpeg, capturedAt: Date())
    let filePath = "/path/to/media.jpg"

    let media = try Media(
        id: mediaID,
        type: mediaType,
        metadata: metadata,
        filePath: filePath)

    #expect(media.id.id == mediaID.value)
}
