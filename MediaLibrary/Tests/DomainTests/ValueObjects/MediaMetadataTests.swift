import Foundation
import Testing

@testable import MediaLibraryDomain

@Test("Media.Metadata - 正常な値で初期化できる")
func mediaMetadataInitialization() async throws {
    let format = MediaFormat.jpeg
    let capturedAt = Date()

    let metadata = Media.Metadata(format: format, capturedAt: capturedAt)

    #expect(metadata.format == format)
    #expect(metadata.capturedAt == capturedAt)
}

@Test("Media.Metadata - 異なる形式での初期化")
func mediaMetadataWithDifferentFormats() async throws {
    let formats: [MediaFormat] = [.jpeg, .png, .heic]
    let capturedAt = Date()

    for format in formats {
        let metadata = Media.Metadata(format: format, capturedAt: capturedAt)
        #expect(metadata.format == format)
        #expect(metadata.capturedAt == capturedAt)
    }
}
