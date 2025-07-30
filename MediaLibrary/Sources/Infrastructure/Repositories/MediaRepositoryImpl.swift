import Foundation
import MediaLibraryDomain
import Photos
#if canImport(UIKit)
import UIKit
#endif

/// PhotoKitを使用したMediaRepositoryの実装
package struct MediaRepositoryImpl: MediaRepository {
    // MARK: - Initialization

    package init() {}

    // MARK: - Public Methods

    package func fetchMedia() async throws -> [Media] {
        print("📱 [MediaRepositoryImpl] fetchMedia開始")
        
        // PHAssetを取得
        let fetchResult = PHAsset.fetchAssets(with: .image, options: createFetchOptions())
        print("📱 [MediaRepositoryImpl] PHAsset取得完了: \(fetchResult.count)件")

        var media: [Media] = []
        fetchResult.enumerateObjects { asset, _, _ in
            do {
                let mediaItem = try self.convertToMedia(from: asset)
                media.append(mediaItem)
            } catch {
                // 個別のアセット変換エラーはログに記録するが、全体の処理は継続
                print("📱 [MediaRepositoryImpl] アセット変換エラー: \(error)")
            }
        }

        print("📱 [MediaRepositoryImpl] Media変換完了: \(media.count)件")
        return media
    }

    package func fetchThumbnail(for mediaID: Media.ID, size: CGSize) async throws -> Media.Thumbnail {
        print("🖼️ [MediaRepositoryImpl] サムネイル取得開始: \(mediaID.value)")
        
        // PHAssetを取得
        guard let asset = await findAsset(by: mediaID) else {
            print("🖼️ [MediaRepositoryImpl] PHAssetが見つからない: \(mediaID.value)")
            throw MediaError.mediaNotFound
        }

        print("🖼️ [MediaRepositoryImpl] PHAsset取得成功: \(mediaID.value)")

        // サムネイル生成
        do {
            let imageData = try await generateThumbnail(from: asset, size: size)
            print("🖼️ [MediaRepositoryImpl] サムネイル生成成功: \(mediaID.value), データサイズ: \(imageData.count)bytes")
            
            return try Media.Thumbnail(
                mediaID: mediaID,
                imageData: imageData,
                size: size
            )
        } catch {
            print("🖼️ [MediaRepositoryImpl] サムネイル生成エラー: \(mediaID.value), エラー: \(error)")
            throw error
        }
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
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat // .opportunisticから変更
            options.resizeMode = .fast

            // continuationが複数回呼ばれることを防ぐためのフラグ
            var isResumed = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                // 既にresumeされている場合は何もしない
                guard !isResumed else { return }

                // degraded画像の場合はスキップ（高品質画像を待つ）
                if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                    return
                }

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

                // UIImageをData形式に変換
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
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
