import MediaLibraryApplication
import UIKit

/// 写真ライブラリ用のCollectionView
final class MediaLibraryCollectionView: UIView {
    // MARK: - Properties

    private let collectionView: UICollectionView
    private weak var viewModel: MediaLibraryViewModel?

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

    /// Delegate、DataSource、PrefetchDataSourceとViewModelを設定
    func configure(delegate: UICollectionViewDelegate & UICollectionViewDataSource & UICollectionViewDataSourcePrefetching, viewModel: MediaLibraryViewModel) {
        collectionView.delegate = delegate
        collectionView.dataSource = delegate
        collectionView.prefetchDataSource = delegate
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
