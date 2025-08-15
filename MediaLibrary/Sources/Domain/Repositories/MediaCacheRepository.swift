import CoreGraphics
import Foundation
import MediaLibraryDomain

/// メディアキャッシュ管理を行うリポジトリプロトコル
package protocol MediaCacheRepository {
    /// 指定されたメディアのプリキャッシュを開始する
    /// - Parameters:
    ///   - media: キャッシュ対象のメディア配列
    ///   - size: サムネイルサイズ
    func startCaching(for media: [Media], size: CGSize)

    /// 指定されたメディアのキャッシュを停止する
    /// - Parameters:
    ///   - media: キャッシュ停止対象のメディア配列
    ///   - size: サムネイルサイズ
    func stopCaching(for media: [Media], size: CGSize)

    /// すべてのキャッシュをクリアする
    func resetCache()
}
