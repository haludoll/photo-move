import Domain
import SwiftUI
import UIKit

/// 写真ライブラリ画面
package struct PhotoLibraryView: View {
    // MARK: - Properties

    @StateObject private var viewModel: PhotoLibraryViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 5)
    private let thumbnailSize = CGSize(width: 200, height: 200)

    // MARK: - Initialization

    package init(viewModel: PhotoLibraryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    package var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.media.isEmpty {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.media.isEmpty {
                    emptyView
                } else {
                    photoGridView
                }
            }
            .navigationTitle("写真")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadPhotos()
            }
            .alert("エラー", isPresented: .constant(viewModel.hasError)) {
                Button("OK") {
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
            Text("写真がありません")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorMessage: String {
        switch viewModel.error {
        case .invalidMediaID:
            return "無効なメディアIDです。"
        case .invalidFilePath:
            return "無効なファイルパスです。"
        case .invalidThumbnailData:
            return "無効なサムネイルデータです。"
        case .permissionDenied:
            return "写真へのアクセスが許可されていません。設定アプリから許可してください。"
        case .mediaNotFound:
            return "写真が見つかりませんでした。"
        case .unsupportedFormat:
            return "サポートされていないファイル形式です。"
        case .thumbnailGenerationFailed:
            return "サムネイルの生成に失敗しました。"
        case .mediaLoadFailed:
            return "写真の読み込みに失敗しました。"
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
