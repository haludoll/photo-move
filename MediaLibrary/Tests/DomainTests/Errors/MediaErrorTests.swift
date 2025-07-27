import Testing

@testable import MediaLibraryDomain

@Test("MediaError - エラーメッセージが正しく設定されている")
func mediaErrorLocalizedDescription() async throws {
    let errors: [(MediaError, String)] = [
        (.invalidMediaID, "Invalid media ID"),
        (.invalidFilePath, "Invalid file path"),
        (.invalidThumbnailData, "Invalid thumbnail data"),
        (.permissionDenied, "Photo library access permission denied. Please allow access in Settings."),
        (.mediaNotFound, "Photo not found"),
        (.unsupportedFormat, "Unsupported file format"),
        (.thumbnailGenerationFailed, "Thumbnail generation failed"),
        (.mediaLoadFailed, "Photo loading failed"),
    ]

    for (error, expectedMessage) in errors {
        #expect(error.localizedDescription == expectedMessage)
    }
}
