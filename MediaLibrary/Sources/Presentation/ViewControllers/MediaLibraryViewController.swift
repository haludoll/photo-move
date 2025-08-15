import MediaLibraryApplication
import MediaLibraryDependencyInjection
import MediaLibraryDomain
import SwiftUI
import UIKit

/// UIKitベースのメディアライブラリ画面
@MainActor
final class MediaLibraryViewController: UIViewController {
    // MARK: - Properties

    private let viewModel: MediaLibraryViewModel
    private var collectionView: UICollectionView!
    private var thumbnailSize: CGSize!
    private var previousPreheatRect = CGRect.zero

    // MARK: - Initialization

    init() {
        viewModel = MediaLibraryViewModel(mediaLibraryService: AppDependencies.mediaLibraryAppService)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()

        // 動的なサムネイルサイズの計算は後で行う
        thumbnailSize = CGSize(width: 200, height: 200) // 初期値

        Task {
            await viewModel.loadPhotos()
            // 初期表示アイテムのサムネイルを読み込み
            loadInitialThumbnails()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // レイアウト確定後にサムネイルサイズを計算
        updateThumbnailSize()
        updateCachedAssets()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Navigation設定
        title = NSLocalizedString("Photos", bundle: .module, comment: "")
        navigationController?.navigationBar.prefersLargeTitles = true

        // CollectionView設定
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        // セル登録
        collectionView.register(
            MediaThumbnailCell.self,
            forCellWithReuseIdentifier: MediaThumbnailCell.identifier
        )

        view.addSubview(collectionView)

        // レイアウト設定
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupBindings() {
        // ViewModelの変更を監視
        viewModel.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.updateUI()
            }
        }.store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private func updateUI() {
        // ローディング状態の処理
        if viewModel.isLoading && viewModel.media.isEmpty {
            showLoadingState()
        } else if viewModel.media.isEmpty {
            showEmptyState()
        } else {
            hideEmptyOrLoadingState()
        }

        // エラー処理
        if viewModel.hasError {
            showError(viewModel.error)
        }

        // CollectionViewの更新（パフォーマンス改善）
        if collectionView.numberOfItems(inSection: 0) != viewModel.media.count {
            // アイテム数が変わった場合のみreloadData
            collectionView.reloadData()
        } else {
            // 表示中のセルのみ更新
            updateVisibleCells()
        }
    }

    private func updateVisibleCells() {
        for cell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell),
                  let thumbnailCell = cell as? MediaThumbnailCell,
                  indexPath.item < viewModel.media.count else { continue }

            let media = viewModel.media[indexPath.item]
            let thumbnail = viewModel.thumbnails[media.id]
            thumbnailCell.configure(with: media, thumbnail: thumbnail)
        }
    }

    private func showLoadingState() {
        // TODO: ローディングビューの表示
    }

    private func showEmptyState() {
        // TODO: 空状態ビューの表示
    }

    private func hideEmptyOrLoadingState() {
        // TODO: ローディング・空状態ビューの非表示
    }

    private func showError(_ error: MediaError?) {
        guard let error = error else { return }

        let alert = UIAlertController(
            title: NSLocalizedString("Error", bundle: .module, comment: ""),
            message: errorMessage(for: error),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: NSLocalizedString("OK", bundle: .module, comment: ""),
            style: .default
        ) { [weak self] _ in
            self?.viewModel.clearError()
        })

        present(alert, animated: true)
    }

    private func loadInitialThumbnails() {
        let visibleItemsCount = min(20, viewModel.media.count) // 最初の20アイテム

        for index in 0 ..< visibleItemsCount {
            let media = viewModel.media[index]
            viewModel.loadThumbnail(for: media.id, size: thumbnailSize)
        }
    }

    // MARK: - Thumbnail Size Management

    /// 実際のセルサイズに基づいてサムネイルサイズを更新
    private func updateThumbnailSize() {
        let columns: CGFloat = 4
        let spacing: CGFloat = 2
        let width = collectionView.bounds.width
        let totalSpacing = spacing * (columns - 1)
        let itemWidth = (width - totalSpacing) / columns

        // 高解像度対応：実際のセルサイズの2倍でサムネイル生成
        let scale = UIScreen.main.scale
        let targetSize = itemWidth * 2 * scale
        thumbnailSize = CGSize(width: targetSize, height: targetSize)
    }

    // MARK: - Cache Management (Apple Sample準拠)

    private func resetCachedAssets() {
        viewModel.resetCache()
        previousPreheatRect = .zero
    }

    private func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }

        // The window you prepare ahead of time is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)

        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }

        // Compute the assets to start and stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedMedia = addedRects
            .flatMap { rect in indexPathsForElements(in: rect) }
            .compactMap { indexPath in
                indexPath.item < viewModel.media.count ? viewModel.media[indexPath.item] : nil
            }
        let removedMedia = removedRects
            .flatMap { rect in indexPathsForElements(in: rect) }
            .compactMap { indexPath in
                indexPath.item < viewModel.media.count ? viewModel.media[indexPath.item] : nil
            }

        // Update the assets the PHCachingImageManager is caching.
        viewModel.startCaching(for: addedMedia, size: thumbnailSize)
        viewModel.stopCaching(for: removedMedia, size: thumbnailSize)

        // Store the computed rectangle for future comparison.
        previousPreheatRect = preheatRect
    }

    private func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        guard let layoutAttributes = collectionView.collectionViewLayout.layoutAttributesForElements(in: rect) else {
            return []
        }
        return layoutAttributes.map { $0.indexPath }
    }

    private func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }

    private func errorMessage(for error: MediaError) -> String {
        switch error {
        case .invalidMediaID:
            return NSLocalizedString("Invalid media ID", bundle: .module, comment: "")
        case .invalidFilePath:
            return NSLocalizedString("Invalid file path", bundle: .module, comment: "")
        case .invalidThumbnailData:
            return NSLocalizedString("Invalid thumbnail data", bundle: .module, comment: "")
        case .permissionDenied:
            return NSLocalizedString("Photo library access permission denied. Please allow access in Settings.", bundle: .module, comment: "")
        case .mediaNotFound:
            return NSLocalizedString("Photo not found", bundle: .module, comment: "")
        case .unsupportedFormat:
            return NSLocalizedString("Unsupported file format", bundle: .module, comment: "")
        case .thumbnailGenerationFailed:
            return NSLocalizedString("Thumbnail generation failed", bundle: .module, comment: "")
        case .mediaLoadFailed:
            return NSLocalizedString("Photo loading failed", bundle: .module, comment: "")
        }
    }
}

// MARK: - UICollectionViewDataSource

extension MediaLibraryViewController: UICollectionViewDataSource {
    func numberOfSections(in _: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return viewModel.media.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MediaThumbnailCell.identifier,
            for: indexPath
        ) as! MediaThumbnailCell

        let media = viewModel.media[indexPath.item]
        let thumbnail = viewModel.thumbnails[media.id]

        // Appleサンプル準拠：representedAssetIdentifierを先に設定
        cell.representedAssetIdentifier = media.id.value

        cell.configure(with: media, thumbnail: thumbnail)

        // Appleサンプル準拠：サムネイルが未取得の場合のみloadThumbnailを実行
        if thumbnail == nil {
            viewModel.loadThumbnail(for: media.id, size: thumbnailSize)
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MediaLibraryViewController: UICollectionViewDelegate {
    // willDisplayでのサムネイル読み込みは削除（prefetchで実行）
}

// MARK: - UIScrollViewDelegate

extension MediaLibraryViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_: UIScrollView) {
        updateCachedAssets()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MediaLibraryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let columns: CGFloat = 4
        let spacing: CGFloat = 2
        let width = collectionView.bounds.width
        let totalSpacing = spacing * (columns - 1)
        let itemWidth = (width - totalSpacing) / columns

        return CGSize(width: itemWidth, height: itemWidth)
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension MediaLibraryViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard indexPath.item < viewModel.media.count else { continue }
            let media = viewModel.media[indexPath.item]
            viewModel.loadThumbnail(for: media.id, size: thumbnailSize)
        }
    }

    func collectionView(_: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard indexPath.item < viewModel.media.count else { continue }
            let media = viewModel.media[indexPath.item]
            viewModel.cancelThumbnailLoading(for: media.id)
        }
    }
}

// MARK: - Combine Import

import Combine
