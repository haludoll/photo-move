import Application
import Domain
import Infrastructure
import SwiftUI
import UIKit

/// 写真ライブラリ画面
public struct PhotoLibraryView: View {
    // MARK: - Properties

    @StateObject private var viewModel: PhotoLibraryViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 5)
    private let thumbnailSize = CGSize(width: 200, height: 200)

    // MARK: - Initialization

    public init() {
        let mediaRepository = MediaRepositoryImpl()
        let permissionService = PhotoLibraryPermissionServiceImpl()
        let appService = MediaLibraryAppServiceImpl(
            mediaRepository: mediaRepository,
            permissionService: permissionService
        )
        _viewModel = StateObject(wrappedValue: PhotoLibraryViewModel(mediaLibraryService: appService))
    }

    // MARK: - Body

    public var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.media.isEmpty {
                    ProgressView(NSLocalizedString("Loading...", bundle: .module, comment: "Loading indicator text"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.media.isEmpty {
                    emptyView
                } else {
                    photoGridView
                }
            }
            .navigationTitle(NSLocalizedString("Photos", bundle: .module, comment: "Navigation title for photos screen"))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadPhotos()
            }
            .alert(NSLocalizedString("Error", bundle: .module, comment: "Error alert title"), isPresented: .constant(viewModel.hasError)) {
                Button(NSLocalizedString("OK", bundle: .module, comment: "OK button text")) {
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
            Text(NSLocalizedString("No Photos", bundle: .module, comment: "Empty state message"))
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorMessage: String {
        switch viewModel.error {
        case .invalidMediaID:
            return NSLocalizedString("Invalid media ID", bundle: .module, comment: "Error message for invalid media ID")
        case .invalidFilePath:
            return NSLocalizedString("Invalid file path", bundle: .module, comment: "Error message for invalid file path")
        case .invalidThumbnailData:
            return NSLocalizedString("Invalid thumbnail data", bundle: .module, comment: "Error message for invalid thumbnail data")
        case .permissionDenied:
            return NSLocalizedString("Photo library access permission denied. Please allow access in Settings.", bundle: .module, comment: "Error message for permission denied")
        case .mediaNotFound:
            return NSLocalizedString("Photo not found", bundle: .module, comment: "Error message for media not found")
        case .unsupportedFormat:
            return NSLocalizedString("Unsupported file format", bundle: .module, comment: "Error message for unsupported format")
        case .thumbnailGenerationFailed:
            return NSLocalizedString("Thumbnail generation failed", bundle: .module, comment: "Error message for thumbnail generation failure")
        case .mediaLoadFailed:
            return NSLocalizedString("Photo loading failed", bundle: .module, comment: "Error message for media load failure")
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
                    .frame(width: size.width / UIScreen.main.scale,
                           height: size.height / UIScreen.main.scale)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size.width / UIScreen.main.scale,
                           height: size.height / UIScreen.main.scale)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            .scaleEffect(0.5)
                    )
            }
        }
    }
}
