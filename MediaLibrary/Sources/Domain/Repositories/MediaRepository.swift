import Foundation

/// メディアライブラリへのアクセスを抽象化するリポジトリ
package protocol MediaRepository: Sendable {
    /// デバイスから利用可能なメディアを取得する
    /// - Returns: メディアの配列
    /// - Throws: MediaError 取得に失敗した場合
    func fetchMedia() async throws -> [Media]

    /// 指定されたメディアのサムネイルを取得する
    /// - Parameters:
    ///   - mediaID: 取得するメディアのID
    ///   - size: サムネイルのサイズ
    /// - Returns: サムネイル画像データ
    /// - Throws: MediaError 取得に失敗した場合
    func fetchThumbnail(for mediaID: Media.ID, size: CGSize) async throws -> Media.Thumbnail

    /// キャッシュリポジトリへの参照を取得する
    var cacheRepository: MediaCacheRepository { get }
}
