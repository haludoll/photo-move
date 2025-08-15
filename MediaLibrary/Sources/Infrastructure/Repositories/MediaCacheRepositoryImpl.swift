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
        let options = createImageRequestOptions()

        imageManager.startCachingImages(
            for: assets,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        )
    }

    package func stopCaching(for media: [Media], size: CGSize) {
        let assets = fetchPHAssets(for: media)
        let options = createImageRequestOptions()

        imageManager.stopCachingImages(
            for: assets,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
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

    private func createImageRequestOptions() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false
        return options
    }
}
