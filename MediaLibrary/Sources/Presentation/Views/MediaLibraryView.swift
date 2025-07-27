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
internal struct MediaLibraryContentView: View {
    // MARK: - Properties
    
    let media: [Media]
    let isLoading: Bool
    let error: MediaError?
    let hasError: Bool
    let thumbnails: [Media.ID: Media.Thumbnail]
    let onLoadPhotos: () -> Void
    let onLoadThumbnail: (Media.ID, CGSize) -> Void
    let onClearError: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 5)
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
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(media) { mediaItem in
                    PhotoThumbnailView(
                        media: mediaItem,
                        thumbnail: thumbnails[mediaItem.id],
                        size: thumbnailSize
                    )
                    .onAppear {
                        onLoadThumbnail(mediaItem.id, thumbnailSize)
                    }
                }
            }
            .padding(.horizontal, 2)
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
            return String(localized: "Invalid media ID", bundle: .module)
        case .invalidFilePath:
            return String(localized: "Invalid file path", bundle: .module)
        case .invalidThumbnailData:
            return String(localized: "Invalid thumbnail data", bundle: .module)
        case .permissionDenied:
            return String(
                localized: "Photo library access permission denied. Please allow access in Settings.", bundle: .module)
        case .mediaNotFound:
            return String(localized: "Photo not found", bundle: .module)
        case .unsupportedFormat:
            return String(localized: "Unsupported file format", bundle: .module)
        case .thumbnailGenerationFailed:
            return String(localized: "Thumbnail generation failed", bundle: .module)
        case .mediaLoadFailed:
            return String(localized: "Photo loading failed", bundle: .module)
        case .none:
            return ""
        }
    }
}

/// 写真サムネイルビュー
private struct PhotoThumbnailView: View {
    let media: Media
    let thumbnail: Media.Thumbnail?
    let size: CGSize

    var body: some View {
        Group {
            if let thumbnail = thumbnail,
                let uiImage = UIImage(data: thumbnail.imageData)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            .scaleEffect(0.5)
                    )
            }
        }
    }
}
