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
        
        // 編集ボタンを追加
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Edit", bundle: .module, comment: ""),
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )

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
        // media配列の変更のみを監視
        viewModel.$media
            .receive(on: DispatchQueue.main)
            .sink { [weak self] media in
                self?.mediaLibraryCollectionView.updateMedia(media)
            }
            .store(in: &cancellables)
            
        // エラーの監視
        viewModel.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.showError(error)
                }
            }
            .store(in: &cancellables)
            
        // サムネイル読み込み完了の監視（PassthroughSubject）
        viewModel.thumbnailLoadedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mediaID in
                self?.mediaLibraryCollectionView.updateVisibleCells()
            }
            .store(in: &cancellables)
            
        // 選択モードの監視
        viewModel.$isSelectionMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSelectionMode in
                self?.updateNavigationForSelectionMode(isSelectionMode)
                self?.mediaLibraryCollectionView.setSelectionMode(isSelectionMode)
            }
            .store(in: &cancellables)
            
        // 選択状態の監視
        viewModel.$selectedMediaIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.mediaLibraryCollectionView.updateVisibleCells()
            }
            .store(in: &cancellables)
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
    
    @objc private func editButtonTapped() {
        if viewModel.isSelectionMode {
            viewModel.exitSelectionMode()
        } else {
            viewModel.enterSelectionMode()
        }
    }
    
    @objc private func cancelButtonTapped() {
        viewModel.exitSelectionMode()
    }
    
    private func updateNavigationForSelectionMode(_ isSelectionMode: Bool) {
        if isSelectionMode {
            // 選択モード時のナビゲーション設定
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: NSLocalizedString("Cancel", bundle: .module, comment: ""),
                style: .plain,
                target: self,
                action: #selector(cancelButtonTapped)
            )
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: NSLocalizedString("Done", bundle: .module, comment: ""),
                style: .done,
                target: self,
                action: #selector(editButtonTapped)
            )
        } else {
            // 通常モード時のナビゲーション設定
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: NSLocalizedString("Edit", bundle: .module, comment: ""),
                style: .plain,
                target: self,
                action: #selector(editButtonTapped)
            )
        }
    }
}
