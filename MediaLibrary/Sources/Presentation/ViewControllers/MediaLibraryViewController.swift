import MediaLibraryApplication
import MediaLibraryDomain
import SwiftUI
import UIKit

/// UIKitベースのメディアライブラリ画面
@MainActor
final class MediaLibraryViewController: UIViewController {
    // MARK: - Properties

    private let viewModel: MediaLibraryViewModel
    private var collectionView: UICollectionView!

    // MARK: - Initialization

    init(viewModel: MediaLibraryViewModel) {
        self.viewModel = viewModel
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

        Task {
            await viewModel.loadPhotos()
        }
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
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        // セル登録
        collectionView.register(
            MediaThumbnailCell.self,
            forCellWithReuseIdentifier: MediaThumbnailCell.identifier
        )

        view.addSubview(collectionView)

        // レイアウト設定
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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

        // CollectionViewの更新
        collectionView.reloadData()
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

        cell.configure(with: media, thumbnail: thumbnail)

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MediaLibraryViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, willDisplay _: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let media = viewModel.media[indexPath.item]
        let thumbnailSize = CGSize(width: 200, height: 200)

        // サムネイル読み込みを開始
        viewModel.loadThumbnail(for: media.id, size: thumbnailSize)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MediaLibraryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let columns: CGFloat = 5
        let spacing: CGFloat = 2
        let width = collectionView.bounds.width
        let totalSpacing = spacing * (columns - 1)
        let itemWidth = (width - totalSpacing) / columns

        return CGSize(width: itemWidth, height: itemWidth)
    }
}

// MARK: - Combine Import

import Combine
