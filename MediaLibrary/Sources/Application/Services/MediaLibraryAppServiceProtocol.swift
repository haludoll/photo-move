import Domain
import Foundation

/// フォトライブラリの操作を提供するApplicationサービスのプロトコル
package protocol MediaLibraryAppServiceProtocol: Sendable {
    /// メディア一覧を取得する
    func loadMedia() async throws -> [Media]

    /// 指定されたメディアのサムネイルを取得する
    func loadThumbnail(for mediaID: Media.ID, size: CGSize) async throws -> Media.Thumbnail
}
