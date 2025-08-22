import Combine
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
    private var mediaLibraryCollectionView: MediaLibraryCollectionView!
    private var cancellables = Set<AnyCancellable>()

    private var loadingView: UIActivityIndicatorView?
    private var emptyStateView: UIView?

    /// CollectionViewへのアクセス用プロパティ
    private var collectionView: UICollectionView {
        return mediaLibraryCollectionView.collectionViewInstance
    }

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

        Task {
            await viewModel.loadPhotos()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mediaLibraryCollectionView.viewDidAppear()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Navigation設定
        title = NSLocalizedString("Photos", bundle: .module, comment: "")
        navigationController?.navigationBar.prefersLargeTitles = true

        // CollectionView設定
        mediaLibraryCollectionView = MediaLibraryCollectionView()
        mediaLibraryCollectionView.translatesAutoresizingMaskIntoConstraints = false
        mediaLibraryCollectionView.configure(viewModel: viewModel)

        view.addSubview(mediaLibraryCollectionView)

        // レイアウト設定
        NSLayoutConstraint.activate([
            mediaLibraryCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
            mediaLibraryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mediaLibraryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mediaLibraryCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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
        mediaLibraryCollectionView.updateData()
    }

    private func showLoadingState() {
        // 既存のビューを隠す
        removeLoadingAndEmptyViews()

        // ローディングビューの作成と表示
        let loadingView = UIActivityIndicatorView(style: .large)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.hidesWhenStopped = true

        view.addSubview(loadingView)

        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        loadingView.startAnimating()
        self.loadingView = loadingView
    }

    private func showEmptyState() {
        // 既存のビューを隠す
        removeLoadingAndEmptyViews()

        // 空状態ビューの作成
        let emptyStateView = UIView()
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false

        // アイコン
        let imageView = UIImageView(image: UIImage(systemName: "photo.on.rectangle"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .systemGray3
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 64)

        // メッセージラベル
        let messageLabel = UILabel()
        messageLabel.text = NSLocalizedString("No Photos", bundle: .module, comment: "")
        messageLabel.textColor = .systemGray
        messageLabel.font = .systemFont(ofSize: 18, weight: .medium)
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        // サブメッセージラベル
        let subMessageLabel = UILabel()
        subMessageLabel.text = NSLocalizedString("Your photo library appears to be empty.", bundle: .module, comment: "")
        subMessageLabel.textColor = .systemGray2
        subMessageLabel.font = .systemFont(ofSize: 14)
        subMessageLabel.textAlignment = .center
        subMessageLabel.numberOfLines = 0
        subMessageLabel.translatesAutoresizingMaskIntoConstraints = false

        // ビューの構成
        emptyStateView.addSubview(imageView)
        emptyStateView.addSubview(messageLabel)
        emptyStateView.addSubview(subMessageLabel)

        view.addSubview(emptyStateView)

        // レイアウト設定
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),

            imageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),

            messageLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),

            subMessageLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            subMessageLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            subMessageLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            subMessageLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor),
        ])

        self.emptyStateView = emptyStateView
    }

    private func hideEmptyOrLoadingState() {
        removeLoadingAndEmptyViews()
    }

    private func removeLoadingAndEmptyViews() {
        loadingView?.stopAnimating()
        loadingView?.removeFromSuperview()
        loadingView = nil

        emptyStateView?.removeFromSuperview()
        emptyStateView = nil
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
