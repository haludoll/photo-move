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
                        // 個別のサムネイル更新を通知
                        self?.objectWillChange.send()
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

    // MARK: - Private Methods

    deinit {
        // MainActorのコンテキストでタスクをキャンセル
        thumbnailLoadingTasks.values.forEach { $0.cancel() }
    }
}
