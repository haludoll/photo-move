import Application
import Domain
import SwiftUI

#if DEBUG

    /// プレビュー用のモックサービス
    private struct MockMediaLibraryAppService: MediaLibraryAppService {
        func loadMedia() async throws -> [Media] {
            // プレビュー用のダミーデータを返す
            return try [
                Media(
                    id: Media.ID("1"),
                    type: .photo,
                    metadata: Media.Metadata(format: .jpeg, capturedAt: Date()),
                    filePath: "dummy1.jpg"
                ),
                Media(
                    id: Media.ID("2"),
                    type: .photo,
                    metadata: Media.Metadata(format: .jpeg, capturedAt: Date()),
                    filePath: "dummy2.jpg"
                ),
                Media(
                    id: Media.ID("3"),
                    type: .photo,
                    metadata: Media.Metadata(format: .png, capturedAt: Date()),
                    filePath: "dummy3.png"
                ),
            ]
        }

        func loadThumbnail(for mediaID: Media.ID, size: CGSize) async throws -> Media.Thumbnail {
            // プレビュー用のダミー画像データを生成
            let image = UIImage(systemName: "photo.fill")!
            let data = image.jpegData(compressionQuality: 0.8)!
            return try Media.Thumbnail(
                mediaID: mediaID,
                imageData: data,
                size: size
            )
        }
    }

    #Preview {
        MediaLibraryView()
    }

#endif
