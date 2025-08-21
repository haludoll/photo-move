import MediaLibraryApplication
import UIKit

/// 写真ライブラリ用のCollectionView
final class MediaLibraryCollectionView: UIView {
    // MARK: - Properties

    private let collectionView: UICollectionView
    private weak var viewModel: MediaLibraryViewModel?
    private var thumbnailSize: CGSize = .init(width: 200, height: 200) // 初期値
    private var previousPreheatRect = CGRect.zero

    /// CollectionViewへのアクセス用プロパティ
    var collectionViewInstance: UICollectionView {
        return collectionView
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        // CollectionView設定
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(frame: frame)

        setupCollectionView()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupCollectionView() {
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        // セル登録
        collectionView.register(
            MediaThumbnailCell.self,
            forCellWithReuseIdentifier: MediaThumbnailCell.identifier
        )
    }

    private func setupLayout() {
        addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - Public Methods

    /// ViewModelを設定してCollectionViewを初期化
    func configure(viewModel: MediaLibraryViewModel) {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        self.viewModel = viewModel
    }

    /// 表示中のセルを更新
    func updateVisibleCells() {
        guard let viewModel = viewModel else { return }

        for cell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell),
                  let thumbnailCell = cell as? MediaThumbnailCell,
                  indexPath.item < viewModel.media.count else { continue }

            let media = viewModel.media[indexPath.item]
            let thumbnail = viewModel.thumbnails[media.id]
            thumbnailCell.configure(with: media, thumbnail: thumbnail)
        }
    }

    /// レイアウト確定後の初期化処理
    func viewDidAppear() {
        updateThumbnailSize()
        loadInitialThumbnails()
        updateCachedAssets()
    }

    /// CollectionViewデータを更新
    func updateData() {
        guard let viewModel = viewModel else { return }

        if collectionView.numberOfItems(inSection: 0) != viewModel.media.count {
            collectionView.reloadData()
        } else {
            updateVisibleCells()
        }
    }

    // MARK: - Private Methods

    private func loadInitialThumbnails() {
        guard let viewModel = viewModel else { return }
        let visibleItemsCount = min(20, viewModel.media.count)

        for index in 0 ..< visibleItemsCount {
            let media = viewModel.media[index]
            viewModel.loadThumbnail(for: media.id, size: thumbnailSize)
        }
    }

    private func updateThumbnailSize() {
        let columns: CGFloat = 4
        let spacing: CGFloat = 2
        let width = collectionView.bounds.width
        let totalSpacing = spacing * (columns - 1)
        let itemWidth = (width - totalSpacing) / columns

        let scale = UIScreen.main.scale
        let targetSize = itemWidth * 2 * scale
        thumbnailSize = CGSize(width: targetSize, height: targetSize)
    }

    private func resetCachedAssets() {
        viewModel?.resetCache()
        previousPreheatRect = .zero
    }

    private func updateCachedAssets() {
        guard let viewModel = viewModel,
              bounds.width > 0 else { return }

        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)

        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > bounds.height / 3 else { return }

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

        viewModel.startCaching(for: addedMedia, size: thumbnailSize)
        viewModel.stopCaching(for: removedMedia, size: thumbnailSize)

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
}

// MARK: - UICollectionViewDataSource

extension MediaLibraryCollectionView: UICollectionViewDataSource {
    func numberOfSections(in _: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return viewModel?.media.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MediaThumbnailCell.identifier,
            for: indexPath
        ) as! MediaThumbnailCell

        guard let viewModel = viewModel,
              indexPath.item < viewModel.media.count
        else {
            return cell
        }

        let media = viewModel.media[indexPath.item]
        let thumbnail = viewModel.thumbnails[media.id]

        cell.representedAssetIdentifier = media.id.value
        cell.configure(with: media, thumbnail: thumbnail)

        if thumbnail == nil {
            viewModel.loadThumbnail(for: media.id, size: thumbnailSize)
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MediaLibraryCollectionView: UICollectionViewDelegate {}

// MARK: - UIScrollViewDelegate

extension MediaLibraryCollectionView: UIScrollViewDelegate {
    func scrollViewDidScroll(_: UIScrollView) {
        updateCachedAssets()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MediaLibraryCollectionView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        return Self.calculateItemSize(for: collectionView.bounds.width)
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension MediaLibraryCollectionView: UICollectionViewDataSourcePrefetching {
    func collectionView(_: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard let viewModel = viewModel else { return }

        for indexPath in indexPaths {
            guard indexPath.item < viewModel.media.count else { continue }
            let media = viewModel.media[indexPath.item]
            viewModel.loadThumbnail(for: media.id, size: thumbnailSize)
        }
    }

    func collectionView(_: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        guard let viewModel = viewModel else { return }

        for indexPath in indexPaths {
            guard indexPath.item < viewModel.media.count else { continue }
            let media = viewModel.media[indexPath.item]
            viewModel.cancelThumbnailLoading(for: media.id)
        }
    }
}

// MARK: - Layout Calculation

extension MediaLibraryCollectionView {
    /// グリッドアイテムのサイズを計算
    static func calculateItemSize(for collectionViewWidth: CGFloat) -> CGSize {
        let columns: CGFloat = 4
        let spacing: CGFloat = 2
        let totalSpacing = spacing * (columns - 1)
        let itemWidth = (collectionViewWidth - totalSpacing) / columns

        return CGSize(width: itemWidth, height: itemWidth)
    }
}
