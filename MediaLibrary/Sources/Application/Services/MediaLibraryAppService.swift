import Foundation
import MediaLibraryDomain

/// フォトライブラリの操作を提供するApplicationサービス
package protocol MediaLibraryAppService: Sendable {
    /// メディア一覧を取得する
    func loadMedia() async throws -> [Media]

    /// 指定されたメディアのサムネイルを取得する
    func loadThumbnail(for mediaID: Media.ID, size: CGSize) async throws -> Media.Thumbnail

    /// 指定されたメディア配列のキャッシュを開始する
    func startCaching(for media: [Media], size: CGSize) async throws

    /// 指定されたメディア配列のキャッシュを停止する
    func stopCaching(for media: [Media], size: CGSize) async throws

    /// すべてのキャッシュをリセットする
    func resetCache() async throws
}
