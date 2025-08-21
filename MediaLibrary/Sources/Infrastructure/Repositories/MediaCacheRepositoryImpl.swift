import Foundation
import MediaLibraryDomain
import Photos
import UIKit

/// PHCachingImageManagerを使用したメディアキャッシュリポジトリの実装
package final class MediaCacheRepositoryImpl: MediaCacheRepository, @unchecked Sendable {
    // MARK: - Properties

    private let imageManager = PHCachingImageManager()

    // MARK: - Initialization

    package init() {}

    // MARK: - MediaCacheRepository

    package func startCaching(for media: [Media], size: CGSize) {
        let assets = fetchPHAssets(for: media)

        // Appleサンプル準拠：キャッシュもデフォルト設定で高速化
        imageManager.startCachingImages(
            for: assets,
            targetSize: size,
            contentMode: .aspectFill,
            options: nil
        )
    }

    package func stopCaching(for media: [Media], size: CGSize) {
        let assets = fetchPHAssets(for: media)

        // Appleサンプル準拠：キャッシュもデフォルト設定で高速化
        imageManager.stopCachingImages(
            for: assets,
            targetSize: size,
            contentMode: .aspectFill,
            options: nil
        )
    }

    package func resetCache() {
        imageManager.stopCachingImagesForAllAssets()
    }

    // MARK: - Internal Methods

    /// PHCachingImageManagerの参照を取得する（MediaRepositoryImplから使用）
    package var cachingImageManager: PHCachingImageManager {
        return imageManager
    }

    // MARK: - Private Methods

    private func fetchPHAssets(for media: [Media]) -> [PHAsset] {
        let identifiers = media.map { $0.id.value }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }
}
