import Testing

@testable import MediaLibraryDomain

@Test("Media.ID - 正常な値で初期化できる")
func mediaIDInitializationWithValidValue() async throws {
    let validID = "PHAsset-123456789"
    let mediaID = try Media.ID(validID)

    #expect(mediaID.value == validID)
    #expect(mediaID.id == validID)
}

@Test("Media.ID - 空文字列で初期化すると失敗する")
func mediaIDInitializationWithEmptyString() async throws {
    #expect(throws: MediaError.invalidMediaID) {
        try Media.ID("")
    }
}

@Test("Media.ID - Hashable protocol準拠")
func mediaIDHashable() async throws {
    let mediaID1 = try Media.ID("test-id-1")
    let mediaID2 = try Media.ID("test-id-1")
    let mediaID3 = try Media.ID("test-id-2")

    #expect(mediaID1.hashValue == mediaID2.hashValue)
    #expect(mediaID1.hashValue != mediaID3.hashValue)
}

@Test("Media.ID - Equatable protocol準拠")
func mediaIDEquatable() async throws {
    let mediaID1 = try Media.ID("test-id-1")
    let mediaID2 = try Media.ID("test-id-1")
    let mediaID3 = try Media.ID("test-id-2")

    #expect(mediaID1 == mediaID2)
    #expect(mediaID1 != mediaID3)
}
