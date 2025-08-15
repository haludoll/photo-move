import Foundation
import MediaLibraryDomain
import Photos
import UIKit

/// PhotoKitを使用したMediaRepositoryの実装
package struct MediaRepositoryImpl: MediaRepository {
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
            // バックグラウンドキューでPhotoKit操作を実行
            DispatchQueue.global(qos: .userInitiated).async {
                let options = PHImageRequestOptions()
                options.isSynchronous = false
                options.deliveryMode = .opportunistic // スピード重視に変更
                options.resizeMode = .fast
                options.isNetworkAccessAllowed = false // ネットワーク経由の取得を無効化

                // continuationが複数回呼ばれることを防ぐためのフラグ
                var isResumed = false
                let lock = NSLock()

                PHImageManager.default().requestImage(
                    for: asset,
                    targetSize: size,
                    contentMode: .aspectFill,
                    options: options
                ) { image, info in
                    lock.lock()
                    defer { lock.unlock() }

                    // 既にresumeされている場合は何もしない
                    guard !isResumed else { return }

                    // degraded画像でも受け入れる（パフォーマンス重視）
                    let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false

                    // エラーチェック
                    if info?[PHImageErrorKey] != nil {
                        isResumed = true
                        continuation.resume(throwing: MediaError.thumbnailGenerationFailed)
                        return
                    }

                    // 画像チェック
                    guard let image = image else {
                        // degraded画像でない場合のみエラーとする
                        if !isDegraded {
                            isResumed = true
                            continuation.resume(throwing: MediaError.thumbnailGenerationFailed)
                        }
                        return
                    }

                    // バックグラウンドキューで画像変換を実行
                    DispatchQueue.global(qos: .userInitiated).async {
                        lock.lock()
                        defer { lock.unlock() }

                        guard !isResumed else { return }

                        // UIImageをData形式に変換（圧縮率を下げてパフォーマンス向上）
                        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
                            isResumed = true
                            continuation.resume(throwing: MediaError.thumbnailGenerationFailed)
                            return
                        }

                        isResumed = true
                        continuation.resume(returning: imageData)
                    }
                }
            }
        }
    }
}
