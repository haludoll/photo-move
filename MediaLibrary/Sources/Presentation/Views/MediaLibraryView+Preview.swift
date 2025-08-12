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
            return Dictionary(uniqueKeysWithValues: media.compactMap { mediaItem in
                let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange]
                let index = abs(mediaItem.id.value.hashValue) % colors.count
                let color = colors[index]

                let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
                let image = UIImage(systemName: "photo.fill", withConfiguration: config)?.withTintColor(color, renderingMode: .alwaysOriginal)
                let data = image?.jpegData(compressionQuality: 0.8) ?? Data()

                guard let thumbnail = try? Media.Thumbnail(
                    mediaID: mediaItem.id,
                    imageData: data,
                    size: CGSize(width: 80, height: 80)
                ) else { return nil }

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

    #Preview("Loading State") {
        MediaLibraryContentView(
            media: [],
            isLoading: true,
            error: nil,
            hasError: false,
            thumbnails: [:],
            isSelectionMode: false,
            selectedMediaIDs: .constant(nil),
            onLoadPhotos: {},
            onLoadThumbnail: { _, _ in },
            onClearError: {},
            onToggleSelectionMode: {}
        )
    }

    #Preview("Empty State") {
        MediaLibraryContentView(
            media: [],
            isLoading: false,
            error: nil,
            hasError: false,
            thumbnails: [:],
            isSelectionMode: false,
            selectedMediaIDs: .constant(nil),
            onLoadPhotos: {},
            onLoadThumbnail: { _, _ in },
            onClearError: {},
            onToggleSelectionMode: {}
        )
    }

    #Preview("With Media") {
        MediaLibraryContentView(
            media: (try? createSampleMedia()) ?? [],
            isLoading: false,
            error: nil,
            hasError: false,
            thumbnails: createSampleThumbnails(),
            isSelectionMode: false,
            selectedMediaIDs: .constant(nil),
            onLoadPhotos: {},
            onLoadThumbnail: { _, _ in },
            onClearError: {},
            onToggleSelectionMode: {}
        )
    }

    #Preview("Permission Error") {
        MediaLibraryContentView(
            media: [],
            isLoading: false,
            error: .permissionDenied,
            hasError: true,
            thumbnails: [:],
            isSelectionMode: false,
            selectedMediaIDs: .constant(nil),
            onLoadPhotos: {},
            onLoadThumbnail: { _, _ in },
            onClearError: {},
            onToggleSelectionMode: {}
        )
    }

    #Preview("Load Failed Error") {
        MediaLibraryContentView(
            media: [],
            isLoading: false,
            error: .mediaLoadFailed,
            hasError: true,
            thumbnails: [:],
            isSelectionMode: false,
            selectedMediaIDs: .constant(nil),
            onLoadPhotos: {},
            onLoadThumbnail: { _, _ in },
            onClearError: {},
            onToggleSelectionMode: {}
        )
    }

    #Preview("Loading with some media") {
        MediaLibraryContentView(
            media: (try? createSampleMedia()) ?? [],
            isLoading: true,
            error: nil,
            hasError: false,
            thumbnails: createSampleThumbnails(),
            isSelectionMode: false,
            selectedMediaIDs: .constant(nil),
            onLoadPhotos: {},
            onLoadThumbnail: { _, _ in },
            onClearError: {},
            onToggleSelectionMode: {}
        )
    }

#endif
