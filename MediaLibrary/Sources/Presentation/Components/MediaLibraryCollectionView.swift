import MediaLibraryApplication
import MediaLibraryDomain
import UIKit

/// DiffableDataSource用のセクション識別子
package enum MediaSection: CaseIterable, Hashable {
    case photos

    package var title: String {
        switch self {
        case .photos:
            return "Photos"
        }
    }
}

/// 写真ライブラリ用のCollectionView
final class MediaLibraryCollectionView: UIView {
    // MARK: - Properties

    private let collectionView: UICollectionView
    private weak var viewModel: MediaLibraryViewModel?
    private var thumbnailSize: CGSize = .init(width: 200, height: 200) // 初期値
    private var previousPreheatRect = CGRect.zero
    private var isSelectionMode: Bool = false

    // MARK: - DiffableDataSource

    private var dataSource: UICollectionViewDiffableDataSource<MediaSection, Media>!

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
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.allowsMultipleSelectionDuringEditing = true

        // セル登録
        collectionView.register(
            MediaThumbnailCell.self,
            forCellWithReuseIdentifier: MediaThumbnailCell.identifier
        )

        setupDataSource()
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<MediaSection, Media>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, media in
            guard let self = self else { return UICollectionViewCell() }

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MediaThumbnailCell.identifier,
                for: indexPath
            ) as! MediaThumbnailCell

            // Appleサンプル準拠：セルの再利用時の混乱を防ぐためIDを先に設定
            cell.representedAssetIdentifier = media.id.value

            // サムネイル取得（既に読み込み済みのもののみ表示）
            let thumbnail = self.viewModel?.thumbnails[media.id]
            let isSelected = self.viewModel?.isSelected(media.id) ?? false

            cell.configure(with: media.id, thumbnail: thumbnail, isSelected: isSelected)

            // サムネイルが未取得の場合のみ読み込みを実行
            if thumbnail == nil {
                self.viewModel?.loadThumbnail(for: media.id, size: self.thumbnailSize)
            }

            return cell
        }
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
        collectionView.prefetchDataSource = self
        self.viewModel = viewModel
    }
    
    /// 選択モードを設定
    func setSelectionMode(_ isSelectionMode: Bool) {
        self.isSelectionMode = isSelectionMode
        collectionView.allowsSelection = isSelectionMode
        collectionView.allowsMultipleSelection = isSelectionMode
        collectionView.allowsMultipleSelectionDuringEditing = isSelectionMode
    }

    /// メディアデータを更新
    func updateMedia(_ media: [Media]) {
        var snapshot = NSDiffableDataSourceSnapshot<MediaSection, Media>()
        snapshot.appendSections([.photos])
        snapshot.appendItems(media, toSection: .photos)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    /// サムネイルを更新
    func updateThumbnail(from mediaID: Media.ID) {
        guard let indexPath = indexPath(for: mediaID),
              let cell = collectionView.cellForItem(at: indexPath) as? MediaThumbnailCell,
              let thumbnail = viewModel?.thumbnails[mediaID] else { return }

        if cell.representedAssetIdentifier == mediaID.value {
            cell.updateThumbnail(with: thumbnail)
        }
    }

    /// 選択状態のみ更新（編集モード切り替え時）
    func updateSelectionState() {
        // 選択状態の変更はスナップショット再適用で効率的に処理
        let snapshot = dataSource.snapshot()
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    /// レイアウト確定後の初期化処理
    func viewDidAppear() {
        updateThumbnailSize()
        loadInitialThumbnails()
        updateCachedAssets()
    }

    // MARK: - Private Methods

    /// 初期表示用サムネイルを読み込み（最初の20件を先行読み込み）
    private func loadInitialThumbnails() {
        guard let viewModel = viewModel else { return }
        let visibleItemsCount = min(20, viewModel.media.count)

        for index in 0 ..< visibleItemsCount {
            let media = viewModel.media[index]
            viewModel.loadThumbnail(for: media.id, size: thumbnailSize)
        }
    }

    /// 実際のセルサイズから高解像度サムネイルサイズを動的計算
    /// - グリッドは4列、スペーシ2pxで固定
    /// - サムネイルはセルサイズ×スクリーン倍率（Appleサンプル準拠）
    private func updateThumbnailSize() {
        let itemSize = GridLayoutCalculator.calculateItemSize(
            containerWidth: collectionView.bounds.width,
            columns: 4,
            spacing: 2
        )

        // Appleサンプル準拠：シンプルにscaleのみ適用
        let scale = UIScreen.main.scale
        thumbnailSize = CGSize(width: itemSize.width * scale, height: itemSize.height * scale)
    }

    private func resetCachedAssets() {
        viewModel?.resetCache()
        previousPreheatRect = .zero
    }

    /// Apple Sample準拠のプリロードキャッシュ管理
    /// - 現在の表示範囲の上下0.5倍の範囲をキャッシュ対象とする
    /// - スクロール量が1/3以上変化した場合のみキャッシュ更新を実行
    private func updateCachedAssets() {
        guard let viewModel = viewModel,
              bounds.width > 0 else { return }

        // 現在の表示範囲を取得
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        // プリロード範囲を作成
        let preheatRect = RectangleDifferenceCalculator.createPreheatRect(from: visibleRect)

        // 前回との差分が小さい場合は処理をスキップ
        let threshold = bounds.height / 3
        guard RectangleDifferenceCalculator.shouldUpdateCache(
            currentRect: preheatRect,
            previousRect: previousPreheatRect,
            threshold: threshold
        ) else { return }

        // 新しいキャッシュ範囲と前回の差分を計算
        let differences = RectangleDifferenceCalculator.calculateDifferences(
            between: previousPreheatRect,
            and: preheatRect
        )
        // 新しくキャッシュするメディアを取得
        let addedMedia = differences.added
            .flatMap { rect in indexPathsForElements(in: rect) }
            .compactMap { indexPath in
                indexPath.item < viewModel.media.count ? viewModel.media[indexPath.item] : nil
            }
        // キャッシュから除去するメディアを取得
        let removedMedia = differences.removed
            .flatMap { rect in indexPathsForElements(in: rect) }
            .compactMap { indexPath in
                indexPath.item < viewModel.media.count ? viewModel.media[indexPath.item] : nil
            }

        // キャッシュを更新（追加・削除）
        viewModel.startCaching(for: addedMedia, size: thumbnailSize)
        viewModel.stopCaching(for: removedMedia, size: thumbnailSize)

        previousPreheatRect = preheatRect
    }

    /// 指定した矩形範囲内に含まれるセルのIndexPathを取得
    private func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        guard let layoutAttributes = collectionView.collectionViewLayout.layoutAttributesForElements(in: rect) else {
            return []
        }
        return layoutAttributes.map { $0.indexPath }
    }
}

// MARK: - UICollectionViewDelegate

extension MediaLibraryCollectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard isSelectionMode,
              let viewModel = viewModel,
              let media = dataSource.itemIdentifier(for: indexPath) else { return }
        
        viewModel.toggleSelection(for: media.id)
        collectionView.deselectItem(at: indexPath, animated: false)
    }
}

// MARK: - UIScrollViewDelegate

extension MediaLibraryCollectionView: UIScrollViewDelegate {
    func scrollViewDidScroll(_: UIScrollView) {
        updateCachedAssets()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MediaLibraryCollectionView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        return GridLayoutCalculator.calculateItemSize(
            containerWidth: collectionView.bounds.width,
            columns: 4,
            spacing: 2
        )
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension MediaLibraryCollectionView: UICollectionViewDataSourcePrefetching {
    /// 表示予定セルのサムネイルを先行読み込み（スムーズなスクロールを実現）
    func collectionView(_: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard let viewModel = viewModel else { return }

        for indexPath in indexPaths {
            guard indexPath.item < viewModel.media.count else { continue }
            let media = viewModel.media[indexPath.item]
            viewModel.loadThumbnail(for: media.id, size: thumbnailSize)
        }
    }

    /// 表示予定がキャンセルされたセルのサムネイル読み込みを中止
    func collectionView(_: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        guard let viewModel = viewModel else { return }

        for indexPath in indexPaths {
            guard indexPath.item < viewModel.media.count else { continue }
            let media = viewModel.media[indexPath.item]
            viewModel.cancelThumbnailLoading(for: media.id)
        }
    }
}


// MARK: - Helper Method

extension MediaLibraryCollectionView {
    /// mediaID から indexPath を取得するヘルパー
    private func indexPath(for mediaID: Media.ID) -> IndexPath? {
        for section in 0..<(dataSource.numberOfSections(in: collectionView)) {
            for itemIndex in 0..<(collectionView.numberOfItems(inSection: section)) {
                let indexPath = IndexPath(item: itemIndex, section: section)
                if let item = dataSource.itemIdentifier(for: indexPath),
                   item.id == mediaID {
                    return indexPath
                }
            }
        }
        return nil
    }
}
