import MediaLibraryDependencyInjection
import MediaLibraryDomain
import SwiftUI
import UIKit

/// メディアライブラリ画面
public struct MediaLibraryView: View {
    // MARK: - Properties

    @StateObject private var viewModel: MediaLibraryViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 5)
    private let thumbnailSize = CGSize(width: 200, height: 200)

    // MARK: - Initialization

    public init() {
        _viewModel = StateObject(
            wrappedValue: MediaLibraryViewModel(mediaLibraryService: AppDependencies.mediaLibraryAppService))
    }

    // MARK: - Body

    public var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.media.isEmpty {
                    ProgressView(String(localized: "Loading...", bundle: .module))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.media.isEmpty {
                    emptyView
                } else {
                    photoGridView
                }
            }
            .navigationTitle(String(localized: "Photos", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadPhotos()
            }
            .alert(String(localized: "Error", bundle: .module), isPresented: .constant(viewModel.hasError)) {
                Button(String(localized: "OK", bundle: .module)) {
                    viewModel.clearError()
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
                ForEach(viewModel.media) { media in
                    PhotoThumbnailView(
                        media: media,
                        thumbnail: viewModel.thumbnails[media.id],
                        size: thumbnailSize
                    )
                    .onAppear {
                        viewModel.loadThumbnail(for: media.id, size: thumbnailSize)
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
        switch viewModel.error {
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
                    .aspectRatio(contentMode: .fill)
                    .frame(
                        width: size.width / UIScreen.main.scale,
                        height: size.height / UIScreen.main.scale
                    )
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(
                        width: size.width / UIScreen.main.scale,
                        height: size.height / UIScreen.main.scale
                    )
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            .scaleEffect(0.5)
                    )
            }
        }
    }
}
