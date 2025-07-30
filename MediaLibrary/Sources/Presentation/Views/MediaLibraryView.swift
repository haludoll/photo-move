import MediaLibraryDependencyInjection
import MediaLibraryDomain
import SwiftUI
import UIKit
import Combine

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
            isSelectionMode: viewModel.isSelectionMode,
            selectedMediaIDs: $viewModel.selectedMediaIDs,
            onLoadPhotos: { Task { await viewModel.loadPhotos() } },
            onLoadThumbnail: viewModel.loadThumbnail,
            onClearError: viewModel.clearError,
            onToggleSelectionMode: viewModel.toggleSelectionMode
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
    let isSelectionMode: Bool
    @Binding var selectedMediaIDs: Set<Media.ID>?
    let onLoadPhotos: () -> Void
    let onLoadThumbnail: (Media.ID, CGSize) -> Void
    let onClearError: () -> Void
    let onToggleSelectionMode: () -> Void

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
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle(String(localized: "Photos", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSelectionMode ? String(localized: "Done", bundle: .module) : String(localized: "Select", bundle: .module)) {
                        onToggleSelectionMode()
                    }
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
            spacing: 2,
            selectedIDs: $selectedMediaIDs
        ) { mediaItem, isSelected in
            let thumbnail = thumbnails[mediaItem.id]
            print("📱 [MediaLibraryView] セル描画: \(mediaItem.id.value), サムネイル: \(thumbnail != nil ? "あり" : "なし")")
            return PhotoThumbnailView(
                media: mediaItem,
                thumbnail: thumbnail,
                size: thumbnailSize,
                isSelected: isSelected,
                isSelectionMode: isSelectionMode
            )
        } onItemAppear: { mediaItem in
            print("📱 [MediaLibraryView] onItemAppear: \(mediaItem.id.value)")
            onLoadThumbnail(mediaItem.id, thumbnailSize)
        }
        .id(thumbnails.count) // thumbnailsが更新されたらGridViewを再構築
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
                localized: "Photo library access permission denied. Please allow access in Settings.", bundle: .module)
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
    let isSelected: Bool
    let isSelectionMode: Bool

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Group {
                    if let thumbnail = thumbnail,
                        let uiImage = UIImage(data: thumbnail.imageData)
                    {
                        let _ = print("🖼️ [PhotoThumbnailView] 画像表示: \(media.id.value)")
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        let _ = print("🖼️ [PhotoThumbnailView] プログレス表示: \(media.id.value), サムネイル: \(thumbnail != nil ? "あり" : "なし")")
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
            .overlay(
                Group {
                    if isSelectionMode {
                        VStack {
                            HStack {
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .background(Color.white.clipShape(Circle()))
                                        .font(.title2)
                                } else {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                        .background(Color.black.opacity(0.3).clipShape(Circle()))
                                }
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                }
            )
            .clipped()
    }
}
