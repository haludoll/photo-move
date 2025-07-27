import MediaLibraryApplication
import MediaLibraryDomain
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
            // プレビュー用の多様なダミー画像データを生成
            let systemImages = ["photo.fill", "camera.fill", "video.fill", "heart.fill", "star.fill"]
            let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPink, .systemPurple]
            
            let index = abs(mediaID.value.hashValue) % systemImages.count
            let imageName = systemImages[index]
            let color = colors[index]
            
            let config = UIImage.SymbolConfiguration(pointSize: min(size.width, size.height) * 0.6, weight: .medium)
            let image = UIImage(systemName: imageName, withConfiguration: config)?.withTintColor(color, renderingMode: .alwaysOriginal)
            
            let data = image?.jpegData(compressionQuality: 0.8) ?? UIImage().jpegData(compressionQuality: 0.8)!
            return try Media.Thumbnail(
                mediaID: mediaID,
                imageData: data,
                size: size
            )
        }
    }

    #Preview {
        MediaLibraryView(viewModel: MediaLibraryViewModel(mediaLibraryService: MockMediaLibraryAppService()))
    }

#endif
