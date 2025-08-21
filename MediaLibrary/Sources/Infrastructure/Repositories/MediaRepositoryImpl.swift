import Foundation
import MediaLibraryDomain
import Photos
import UIKit

/// PhotoKitを使用したMediaRepositoryの実装
package struct MediaRepositoryImpl: MediaRepository {
    // MARK: - Properties

    package let cacheRepository: MediaCacheRepository

    // MARK: - Initialization

    package init(cacheRepository: MediaCacheRepository = MediaCacheRepositoryImpl()) {
        self.cacheRepository = cacheRepository
    }

    // MARK: - Public Methods

    package func fetchMedia() async throws -> [Media] {
        // PHAssetを取得
        let fetchResult = PHAsset.fetchAssets(with: .image, options: createFetchOptions())

        var media: [Media] = []
        fetchResult.enumerateObjects { asset, _, _ in
            do {
                let mediaItem = try self.convertToMedia(from: asset)
                media.append(mediaItem)
            } catch {
                // 個別のアセット変換エラーはログに記録するが、全体の処理は継続
                print("Failed to convert asset to media: \(error)")
            }
        }

        return media
    }

    package func fetchThumbnail(for mediaID: Media.ID, size: CGSize) async throws -> Media.Thumbnail {
        // PHAssetを取得
        guard let asset = await findAsset(by: mediaID) else {
            throw MediaError.mediaNotFound
        }

        // サムネイル生成
        let imageData = try await generateThumbnail(from: asset, size: size)

        return try Media.Thumbnail(
            mediaID: mediaID,
            imageData: imageData,
            size: size
        )
    }

    // MARK: - Private Methods

    private func createFetchOptions() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false),
        ]
        return options
    }

    private func convertToMedia(from asset: PHAsset) throws -> Media {
        let mediaID = try Media.ID(asset.localIdentifier)
        let metadata = Media.Metadata(
            format: convertMediaFormat(from: asset),
            capturedAt: asset.creationDate ?? Date()
        )

        return try Media(
            id: mediaID,
            type: .photo,
            metadata: metadata,
            filePath: asset.localIdentifier // PhotoKitではlocalIdentifierをファイルパスとして使用
        )
    }

    private func convertMediaFormat(from _: PHAsset) -> MediaFormat {
        // PhotoKitではフォーマット情報を直接取得できないため、
        // 一般的なケースとしてJPEGを返す
        return .jpeg
    }

    private func findAsset(by mediaID: Media.ID) async -> PHAsset? {
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [mediaID.value],
            options: nil
        )
        return fetchResult.firstObject
    }

    private func generateThumbnail(from asset: PHAsset, size: CGSize) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            // PHCachingImageManagerの参照を取得
            let imageManager: PHCachingImageManager
            if let cacheImpl = cacheRepository as? MediaCacheRepositoryImpl {
                imageManager = cacheImpl.cachingImageManager
            } else {
                imageManager = PHCachingImageManager()
            }

            // Appleサンプル準拠：サムネイルはデフォルト設定で高速化
            let options: PHImageRequestOptions? = nil

            // continuationが複数回呼ばれることを防ぐためのフラグ
            var isResumed = false

            imageManager.requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                // 既にresumeされている場合は何もしない
                guard !isResumed else { return }

                // エラーチェック
                if info?[PHImageErrorKey] != nil {
                    isResumed = true
                    continuation.resume(throwing: MediaError.thumbnailGenerationFailed)
                    return
                }

                // 画像チェック
                guard let image = image else {
                    isResumed = true
                    continuation.resume(throwing: MediaError.thumbnailGenerationFailed)
                    return
                }

                // アルファチャンネルを除去してUIImageをData形式に変換
                let processedImage = removeAlphaChannel(from: image)
                guard let imageData = processedImage.jpegData(compressionQuality: 0.8) else {
                    isResumed = true
                    continuation.resume(throwing: MediaError.thumbnailGenerationFailed)
                    return
                }

                isResumed = true
                continuation.resume(returning: imageData)
            }
        }
    }

    // MARK: - Private Methods

    /// アルファチャンネルを除去して不透明な画像に変換
    private func removeAlphaChannel(from image: UIImage) -> UIImage {
        let size = image.size
        let scale = image.scale

        // RGB形式のコンテキストを作成（アルファチャンネルなし）
        UIGraphicsBeginImageContextWithOptions(size, true, scale)
        defer { UIGraphicsEndImageContext() }

        // 白背景で描画
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))

        // 元画像を描画
        image.draw(in: CGRect(origin: .zero, size: size))

        // 新しい画像を生成
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}
