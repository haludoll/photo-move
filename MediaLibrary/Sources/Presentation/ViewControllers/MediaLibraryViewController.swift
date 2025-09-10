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
    private var floatingButton: UIButton!

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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // ナビゲーションバーを非表示
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mediaLibraryCollectionView.viewDidAppear()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // CollectionView設定
        mediaLibraryCollectionView = MediaLibraryCollectionView()
        mediaLibraryCollectionView.translatesAutoresizingMaskIntoConstraints = false
        mediaLibraryCollectionView.configure(viewModel: viewModel)

        view.addSubview(mediaLibraryCollectionView)

        // フローティングボタン設定
        setupFloatingButton()

        // レイアウト設定
        NSLayoutConstraint.activate([
            mediaLibraryCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
            mediaLibraryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mediaLibraryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mediaLibraryCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func setupFloatingButton() {
        floatingButton = UIButton(type: .system)
        floatingButton.translatesAutoresizingMaskIntoConstraints = false
        
        // ガラス効果のblur背景を追加
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.layer.cornerRadius = 18
        blurEffectView.clipsToBounds = true
        
        // ボタンの基本設定
        updateFloatingButtonAppearance()
        floatingButton.addTarget(self, action: #selector(floatingButtonTapped), for: .touchUpInside)
        
        view.addSubview(blurEffectView)
        view.addSubview(floatingButton)
        
        // レイアウト設定（右上に配置）
        NSLayoutConstraint.activate([
            // blur背景のレイアウト
            blurEffectView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            blurEffectView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            blurEffectView.heightAnchor.constraint(equalToConstant: 36),
            blurEffectView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // ボタンのレイアウト（blur背景と同じ位置）
            floatingButton.topAnchor.constraint(equalTo: blurEffectView.topAnchor),
            floatingButton.leadingAnchor.constraint(equalTo: blurEffectView.leadingAnchor),
            floatingButton.trailingAnchor.constraint(equalTo: blurEffectView.trailingAnchor),
            floatingButton.bottomAnchor.constraint(equalTo: blurEffectView.bottomAnchor)
        ])
    }
    
    private func updateFloatingButtonAppearance() {
        if viewModel.isSelectionMode {
            floatingButton.setTitle(NSLocalizedString("Done", bundle: .module, comment: ""), for: .normal)
        } else {
            floatingButton.setTitle(NSLocalizedString("Edit", bundle: .module, comment: ""), for: .normal)
        }
        
        // ガラス効果背景なので背景色は透明に
        floatingButton.backgroundColor = .clear
        floatingButton.setTitleColor(.label, for: .normal)
        
        // iOS 15以降の新しい方法でパディングを設定
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            floatingButton.configuration = config
        } else {
            floatingButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        }
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
                self?.updateFloatingButtonAppearance()
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
    
    // MARK: - Editing Mode
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        if isEditing != editing {
            super.setEditing(editing, animated: animated)
            collectionView.isEditing = editing
            
            // Reload visible items to make sure our collection view cells show their selection indicators.
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
            if !editing {
                // Clear selection if leaving edit mode.
                collectionView.indexPathsForSelectedItems?.forEach({ (indexPath) in
                    collectionView.deselectItem(at: indexPath, animated: animated)
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
    
    @objc private func floatingButtonTapped() {
        // Toggle selection state.
        setEditing(!isEditing, animated: true)
    }
}
