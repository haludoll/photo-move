import Testing
@testable import Domain

@Test("MediaError - エラーメッセージが正しく設定されている")
func mediaErrorLocalizedDescription() async throws {
    let errors: [(MediaError, String)] = [
        (.invalidMediaID, "Invalid media ID"),
        (.invalidFilePath, "Invalid file path"),
        (.invalidThumbnailData, "Invalid thumbnail data"),
        (.permissionDenied, "Photo library access permission denied"),
        (.mediaNotFound, "Media not found"),
        (.unsupportedFormat, "Unsupported file format"),
        (.thumbnailGenerationFailed, "Thumbnail generation failed"),
        (.mediaLoadFailed, "Media loading failed")
    ]

    for (error, expectedMessage) in errors {
        #expect(error.localizedDescription == expectedMessage)
    }
}
