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
    private var selectionModeButtonHostingController: UIHostingController<MediaSelectionModeButton>!

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

        // CollectionView設定
        mediaLibraryCollectionView = MediaLibraryCollectionView(viewModel: viewModel)
        mediaLibraryCollectionView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mediaLibraryCollectionView)

        // 選択モードボタン設定
        setupSelectionModeButton()

        // レイアウト設定
        NSLayoutConstraint.activate([
            mediaLibraryCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
            mediaLibraryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mediaLibraryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mediaLibraryCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupSelectionModeButton() {
        let selectionModeButton = MediaSelectionModeButton(isSelectionMode: viewModel.isSelectionMode) { [weak self] in
            self?.toggleSelectionMode()
        }

        selectionModeButtonHostingController = embed(selectionModeButton, at: .topTrailing)
    }

    private func updateSelectionModeButton() {
        let updatedButton = MediaSelectionModeButton(
            isSelectionMode: viewModel.isSelectionMode
        ) { [weak self] in
            self?.toggleSelectionMode()
        }

        selectionModeButtonHostingController.rootView = updatedButton
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

        viewModel.thumbnailLoadedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mediaID in
                self?.mediaLibraryCollectionView.updateThumbnail(from: mediaID)
            }
            .store(in: &cancellables)

        // 選択モードの監視
        viewModel.$isSelectionMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSelectionMode in
                self?.updateSelectionModeButton()
                self?.mediaLibraryCollectionView.setSelectionMode(isSelectionMode)
            }
            .store(in: &cancellables)
            
        // 選択状態の監視
        viewModel.$selectedMediaIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.mediaLibraryCollectionView.updateSelectionState()
            }
            .store(in: &cancellables)
    }

    private func showError(_ error: MediaError?) {
        guard let error = error else { return }

        let alert = UIAlertController(
            title: String(localized: "Error", bundle: .module),
            message: error.localizedMessage,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: String(localized: "OK", bundle: .module),
            style: .default
        ) { [weak self] _ in
            self?.viewModel.clearError()
        })

        present(alert, animated: true)
    }
    
    // MARK: - Editing Mode
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        if isEditing != editing {
            super.setEditing(editing, animated: animated)
            mediaLibraryCollectionView.collectionView.isEditing = editing

            // DiffableDataSourceを使用しているため、CollectionView経由でセルを更新
            mediaLibraryCollectionView.updateSelectionState()
            
            if !editing {
                // Clear selection if leaving edit mode.
                mediaLibraryCollectionView.collectionView.indexPathsForSelectedItems?.forEach({ (indexPath) in
                    mediaLibraryCollectionView.collectionView.deselectItem(at: indexPath, animated: animated)
                })
            }
            
            updateUserInterface()
        }
    }
    
    private func updateUserInterface() {
        // ViewModelの選択モード状態を更新
        if isEditing && !viewModel.isSelectionMode {
            viewModel.enterSelectionMode()
        } else if !isEditing && viewModel.isSelectionMode {
            viewModel.exitSelectionMode()
        }
    }
    
    private func toggleSelectionMode() {
        // Toggle selection state.
        setEditing(!isEditing, animated: true)
    }
}

// MARK: - MediaError Extension

extension MediaError {
    /// ユーザー向けのローカライズされたエラーメッセージ
    var localizedMessage: String {
        switch self {
        case .invalidMediaID:
            String(localized: "Invalid media ID", bundle: .module)
        case .invalidFilePath:
            String(localized: "Invalid file path", bundle: .module)
        case .invalidThumbnailData:
            String(localized: "Invalid thumbnail data", bundle: .module)
        case .permissionDenied:
            String(localized: "Photo library access permission denied. Please allow access in Settings.", bundle: .module)
        case .mediaNotFound:
            String(localized: "Photo not found", bundle: .module)
        case .unsupportedFormat:
            String(localized: "Unsupported file format", bundle: .module)
        case .thumbnailGenerationFailed:
            String(localized: "Thumbnail generation failed", bundle: .module)
        case .mediaLoadFailed:
            String(localized: "Photo loading failed", bundle: .module)
        }
    }
}
