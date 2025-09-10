import MediaLibraryDomain
import SwiftUI
import UIKit

#if DEBUG

    // MARK: - Preview Data

    private func createSampleMedia() throws -> [Media] {
        return try [
            Media(
                id: Media.ID("1"),
                type: .photo,
                metadata: Media.Metadata(format: .jpeg, capturedAt: Date()),
                filePath: "photo1.jpg"
            ),
            Media(
                id: Media.ID("2"),
                type: .photo,
                metadata: Media.Metadata(format: .png, capturedAt: Date()),
                filePath: "photo2.png"
            ),
            Media(
                id: Media.ID("3"),
                type: .photo,
                metadata: Media.Metadata(format: .jpeg, capturedAt: Date()),
                filePath: "photo3.jpg"
            ),
        ]
    }

    private func createSampleThumbnails() -> [Media.ID: Media.Thumbnail] {
        do {
            let media = try createSampleMedia()
            return Dictionary(uniqueKeysWithValues: try media.compactMap { mediaItem in
                let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange]
                let index = abs(mediaItem.id.value.hashValue) % colors.count
                let color = colors[index]

                let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
                let image = UIImage(systemName: "photo.fill", withConfiguration: config)?.withTintColor(color, renderingMode: .alwaysOriginal) ?? UIImage()

                let thumbnail = try Media.Thumbnail.from(
                    mediaID: mediaItem.id,
                    image: image,
                    size: CGSize(width: 80, height: 80)
                )

                return (mediaItem.id, thumbnail)
            })
        } catch {
            return [:]
        }
    }

    // MARK: - Previews

    #Preview("Default - with DI") {
        MediaLibraryView()
    }

    // プレビューは基本のMediaLibraryViewのみ提供
    // 詳細な状態テストはUIテストで行う

#endif
