import MediaLibraryDependencyInjection
import MediaLibraryDomain
import SwiftUI
import UIKit

/// メディアライブラリ画面（Stateful Container）
public struct MediaLibraryView: View {
    // MARK: - Properties

    @StateObject private var viewModel: MediaLibraryViewModel

    // MARK: - Initialization

    public init() {
        _viewModel = StateObject(
            wrappedValue: MediaLibraryViewModel(mediaLibraryService: AppDependencies.mediaLibraryAppService))
    }

    // MARK: - Body

    public var body: some View {
        MediaLibraryContentView(
            media: viewModel.media,
            isLoading: viewModel.isLoading,
            error: viewModel.error,
            hasError: viewModel.hasError,
            thumbnails: viewModel.thumbnails,
            onLoadPhotos: { Task { await viewModel.loadPhotos() } },
            onLoadThumbnail: viewModel.loadThumbnail,
            onClearError: viewModel.clearError
        )
        .task {
            await viewModel.loadPhotos()
        }
    }
}

/// メディアライブラリ画面のコンテンツ（Stateless Presenter）
struct MediaLibraryContentView: View {
    // MARK: - Properties

    let media: [Media]
    let isLoading: Bool
    let error: MediaError?
    let hasError: Bool
    let thumbnails: [Media.ID: Media.Thumbnail]
    let onLoadPhotos: () -> Void
    let onLoadThumbnail: (Media.ID, CGSize) -> Void
    let onClearError: () -> Void

    private let thumbnailSize = CGSize(width: 200, height: 200)

    // MARK: - Body

    var body: some View {
        NavigationView {
            Group {
                if isLoading && media.isEmpty {
                    ProgressView(String(localized: "Loading...", bundle: .module))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if media.isEmpty {
                    emptyView
                } else {
                    photoGridView
                }
            }
            .alert(String(localized: "Error", bundle: .module), isPresented: .constant(hasError)) {
                Button(String(localized: "OK", bundle: .module)) {
                    onClearError()
                }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Private Views

    private var photoGridView: some View {
        GridView(
            items: media,
            columns: 5,
            spacing: 2
        ) { mediaItem in
            PhotoThumbnailView(
                media: mediaItem,
                thumbnail: thumbnails[mediaItem.id],
                size: thumbnailSize
            )
        } onItemAppear: { mediaItem in
            onLoadThumbnail(mediaItem.id, thumbnailSize)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            Text(String(localized: "No Photos", bundle: .module))
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorMessage: String {
        switch error {
        case .invalidMediaID:
            String(localized: "Invalid media ID", bundle: .module)
        case .invalidFilePath:
            String(localized: "Invalid file path", bundle: .module)
        case .invalidThumbnailData:
            String(localized: "Invalid thumbnail data", bundle: .module)
        case .permissionDenied:
            String(
                localized: "Photo library access permission denied. Please allow access in Settings.", bundle: .module
            )
        case .mediaNotFound:
            String(localized: "Photo not found", bundle: .module)
        case .unsupportedFormat:
            String(localized: "Unsupported file format", bundle: .module)
        case .thumbnailGenerationFailed:
            String(localized: "Thumbnail generation failed", bundle: .module)
        case .mediaLoadFailed:
            String(localized: "Photo loading failed", bundle: .module)
        case .none:
            ""
        }
    }
}

/// 写真サムネイルビュー
private struct PhotoThumbnailView: View {
    let media: Media
    let thumbnail: Media.Thumbnail?
    let size: CGSize

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Group {
                    if let thumbnail = thumbnail,
                       let uiImage = UIImage(data: thumbnail.imageData)
                    {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .scaleEffect(0.5)
                            )
                    }
                }
            )
            .clipped()
    }
}
