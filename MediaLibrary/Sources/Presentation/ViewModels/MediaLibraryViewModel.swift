import MediaLibraryApplication
import Combine
import MediaLibraryDomain
import Foundation
import SwiftUI

/// メディアライブラリ画面のViewModel
@MainActor
class MediaLibraryViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var media: [Media] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: MediaError?
    @Published private(set) var permissionStatus: PhotoLibraryPermissionStatus = .notDetermined
    @Published private(set) var thumbnails: [Media.ID: Media.Thumbnail] = [:]
    @Published private(set) var isSelectionMode = false
    @Published var selectedMediaIDs: Set<Media.ID>? = nil

    // MARK: - Private Properties

    private let mediaLibraryService: any MediaLibraryAppService
    private var thumbnailLoadingTasks: [Media.ID: Task<Void, Never>] = [:]

    // MARK: - Computed Properties

    var hasError: Bool {
        error != nil
    }

    // MARK: - Initialization

    init(mediaLibraryService: any MediaLibraryAppService) {
        self.mediaLibraryService = mediaLibraryService
    }

    // MARK: - Public Methods

    /// 写真を読み込む
    func loadPhotos() async {
        print("📸 [MediaLibraryViewModel] loadPhotos開始")
        isLoading = true
        error = nil

        do {
            media = try await mediaLibraryService.loadMedia()
            print("📸 [MediaLibraryViewModel] \(media.count)件の写真を読み込み完了")
        } catch let mediaError as MediaError {
            print("📸 [MediaLibraryViewModel] MediaErrorが発生: \(mediaError)")
            error = mediaError
            media = []
        } catch {
            print("📸 [MediaLibraryViewModel] 予期しないエラーが発生: \(error)")
            self.error = .mediaLoadFailed
            media = []
        }

        isLoading = false
    }

    /// サムネイルを読み込む
    /// - Parameters:
    ///   - mediaID: メディアID
    ///   - size: サムネイルサイズ
    func loadThumbnail(for mediaID: Media.ID, size: CGSize) {
        // すでに読み込み中または読み込み済みの場合はスキップ
        if thumbnails[mediaID] != nil || thumbnailLoadingTasks[mediaID] != nil {
            print("🖼️ [MediaLibraryViewModel] サムネイル読み込みスキップ: \(mediaID.value)")
            return
        }

        print("🖼️ [MediaLibraryViewModel] サムネイル読み込み開始: \(mediaID.value)")

        // サムネイル読み込みタスクを開始
        let task = Task { [weak self] in
            do {
                let thumbnail = try await self?.mediaLibraryService.loadThumbnail(
                    for: mediaID,
                    size: size
                )

                if let thumbnail = thumbnail {
                    print("🖼️ [MediaLibraryViewModel] サムネイル読み込み成功: \(mediaID.value)")
                    await MainActor.run {
                        self?.thumbnails[mediaID] = thumbnail
                    }
                } else {
                    print("🖼️ [MediaLibraryViewModel] サムネイルがnil: \(mediaID.value)")
                }
            } catch {
                // サムネイル読み込みエラーは個別に処理せず、デフォルト画像を表示
                print("🖼️ [MediaLibraryViewModel] サムネイル読み込みエラー \(mediaID.value): \(error)")
            }

            await MainActor.run {
                self?.thumbnailLoadingTasks[mediaID] = nil
            }
        }

        thumbnailLoadingTasks[mediaID] = task
    }

    /// エラーをクリアする
    func clearError() {
        error = nil
    }
    
    /// 選択モードの切り替え
    func toggleSelectionMode() {
        isSelectionMode.toggle()
        if isSelectionMode {
            // 選択モードに入る時は空のSetを作成
            selectedMediaIDs = Set<Media.ID>()
        } else {
            // 選択モードを終了する時はnilに
            selectedMediaIDs = nil
        }
    }

    /// すべてのサムネイル読み込みタスクをキャンセルする
    func cancelAllThumbnailTasks() {
        thumbnailLoadingTasks.values.forEach { $0.cancel() }
        thumbnailLoadingTasks.removeAll()
    }

    // MARK: - Private Methods

    deinit {
        // MainActorのコンテキストでタスクをキャンセル
        thumbnailLoadingTasks.values.forEach { $0.cancel() }
    }
}
