import Combine
import Foundation
import MediaLibraryApplication
import MediaLibraryDomain
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
    @Published var selectedMediaIDs: Set<Media.ID> = []
    @Published private(set) var isSelectionMode: Bool = false
    
    // サムネイル読み込み完了の通知用Subject
    let thumbnailLoadedSubject = PassthroughSubject<Media.ID, Never>()

    // MARK: - Private Properties

    private let mediaLibraryService: any MediaLibraryAppService
    private var thumbnailLoadingTasks: [Media.ID: Task<Void, Never>] = [:]

    // MARK: - Computed Properties

    var hasError: Bool {
        error != nil
    }
    
    /// 選択されたメディア一覧
    var selectedMedia: [Media] {
        media.filter { selectedMediaIDs.contains($0.id) }
    }
    
    /// 選択されたメディアの数
    var selectedCount: Int {
        selectedMediaIDs.count
    }

    // MARK: - Initialization

    init(mediaLibraryService: any MediaLibraryAppService) {
        self.mediaLibraryService = mediaLibraryService
    }

    // MARK: - Public Methods

    /// 写真を読み込む
    func loadPhotos() async {
        isLoading = true
        error = nil

        do {
            media = try await mediaLibraryService.loadMedia()
        } catch let mediaError as MediaError {
            error = mediaError
            media = []
        } catch {
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
            return
        }

        // サムネイル読み込みタスクを開始
        let task = Task { [weak self] in
            do {
                let thumbnail = try await self?.mediaLibraryService.loadThumbnail(
                    for: mediaID,
                    size: size
                )

                if let thumbnail = thumbnail {
                    await MainActor.run {
                        self?.thumbnails[mediaID] = thumbnail
                        // PassthroughSubject経由で効率的に通知
                        self?.thumbnailLoadedSubject.send(mediaID)
                    }
                }
            } catch {
                // サムネイル読み込みエラーは個別に処理せず、デフォルト画像を表示
                print("Failed to load thumbnail for \(mediaID.value): \(error)")
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

    /// 特定のメディアIDのサムネイル読み込みタスクをキャンセルする
    /// - Parameter mediaID: キャンセルするメディアID
    func cancelThumbnailLoading(for mediaID: Media.ID) {
        thumbnailLoadingTasks[mediaID]?.cancel()
        thumbnailLoadingTasks[mediaID] = nil
    }

    /// すべてのサムネイル読み込みタスクをキャンセルする
    func cancelAllThumbnailTasks() {
        thumbnailLoadingTasks.values.forEach { $0.cancel() }
        thumbnailLoadingTasks.removeAll()
    }

    /// 指定されたメディア配列のプリキャッシュを開始する（Appleサンプル準拠）
    /// - Parameters:
    ///   - media: キャッシュ対象のメディア配列
    ///   - size: サムネイルサイズ
    func startCaching(for media: [Media], size: CGSize) {
        Task {
            do {
                try await mediaLibraryService.startCaching(for: media, size: size)
            } catch {
                print("Failed to start caching: \(error)")
            }
        }
    }

    /// 指定されたメディア配列のキャッシュを停止する（Appleサンプル準拠）
    /// - Parameters:
    ///   - media: キャッシュ停止対象のメディア配列
    ///   - size: サムネイルサイズ
    func stopCaching(for media: [Media], size: CGSize) {
        Task {
            do {
                try await mediaLibraryService.stopCaching(for: media, size: size)
            } catch {
                print("Failed to stop caching: \(error)")
            }
        }
    }

    /// すべてのキャッシュをリセットする（Appleサンプル準拠）
    func resetCache() {
        Task {
            do {
                try await mediaLibraryService.resetCache()
            } catch {
                print("Failed to reset cache: \(error)")
            }
        }
    }

    // MARK: - Selection Methods
    
    /// 選択モードを開始する
    func enterSelectionMode() {
        isSelectionMode = true
    }
    
    /// 選択モードを終了する
    func exitSelectionMode() {
        isSelectionMode = false
        selectedMediaIDs.removeAll()
    }
    
    /// メディアが選択されているかどうかを確認する
    /// - Parameter mediaID: 確認するメディアID
    /// - Returns: 選択されている場合はtrue
    func isSelected(_ mediaID: Media.ID) -> Bool {
        selectedMediaIDs.contains(mediaID)
    }
    
    /// メディアの選択状態を切り替える（選択モード時のみ）
    /// - Parameter mediaID: 切り替えるメディアID
    func toggleSelection(for mediaID: Media.ID) {
        guard isSelectionMode else { return }
        
        if selectedMediaIDs.contains(mediaID) {
            selectedMediaIDs.remove(mediaID)
        } else {
            selectedMediaIDs.insert(mediaID)
        }
    }
    
    /// すべての選択を解除する
    func clearSelection() {
        selectedMediaIDs.removeAll()
    }
    
    /// すべてのメディアを選択する
    func selectAll() {
        selectedMediaIDs = Set(media.map(\.id))
    }

    // MARK: - Private Methods

    deinit {
        // MainActorのコンテキストでタスクをキャンセル
        thumbnailLoadingTasks.values.forEach { $0.cancel() }
    }
}
