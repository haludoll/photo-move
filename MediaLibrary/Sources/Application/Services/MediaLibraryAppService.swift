import Foundation
import MediaLibraryDomain

/// フォトライブラリの操作を提供するApplicationサービス
package protocol MediaLibraryAppService: Sendable {
    /// メディア一覧を取得する
    func loadMedia() async throws -> [Media]

    /// 指定されたメディアのサムネイルを取得する
    func loadThumbnail(for mediaID: Media.ID, size: CGSize) async throws -> Media.Thumbnail
}
