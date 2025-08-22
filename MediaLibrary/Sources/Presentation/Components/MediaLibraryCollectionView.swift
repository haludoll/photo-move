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
        
        // DEBUG: 実際のサイズを出力
        print("📱 Our App - Cell size: \(itemSize), Scale: \(scale), Thumbnail size: \(thumbnailSize)")
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

        // Apple Sample準拠: セルの再利用時の混乱を防ぐためIDを先に設定
        cell.representedAssetIdentifier = media.id.value
        cell.configure(with: media, thumbnail: thumbnail)

        // サムネイルが未取得の場合のみ読み込みを実行（重複読み込み防止）
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
