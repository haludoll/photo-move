import Domain
import Foundation

/// MediaLibraryServiceのプロトコル
@available(iOS 15.0, macOS 11.0, *)
package protocol MediaLibraryServiceProtocol: Sendable {
    /// メディア一覧を取得する
    /// - Returns: メディア一覧
    /// - Throws: MediaError
    func loadMedia() async throws -> [Media]

    /// 指定されたメディアのサムネイルを取得する
    /// - Parameters:
    ///   - mediaID: メディアID
    ///   - size: サムネイルサイズ
    /// - Returns: サムネイルデータ
    /// - Throws: MediaError
    func loadThumbnail(for mediaID: Media.ID, size: CGSize) async throws -> Media.Thumbnail
}

/// MediaLibraryServiceのプロトコル準拠
@available(iOS 15.0, macOS 11.0, *)
extension MediaLibraryService: MediaLibraryServiceProtocol {}
