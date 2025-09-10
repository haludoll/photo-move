import Foundation
import MediaLibraryDomain
import Photos
import UIKit

/// PhotoKitを使用したMediaRepositoryの実装
package struct MediaRepositoryImpl: MediaRepository {
    // MARK: - Properties
    
    private let imageManager = PHImageManager()

    // MARK: - Initialization

    package init() {}

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
        let image = try await generateThumbnail(from: asset, size: size)
        
        // UIImageからDataに変換
        guard let imageData = image.pngData() else {
            throw MediaError.invalidThumbnailData
        }

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

    private func generateThumbnail(from asset: PHAsset, size: CGSize) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            // 高品質サムネイル取得のためのオプション設定
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

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

                // Appleサンプル準拠：UIImageをそのまま返す
                isResumed = true
                continuation.resume(returning: image)
            }
        }
    }
}
