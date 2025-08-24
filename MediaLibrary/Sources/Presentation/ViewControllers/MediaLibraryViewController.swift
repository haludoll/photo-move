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
        
        // ボタンの基本設定
        updateFloatingButtonAppearance()
        floatingButton.addTarget(self, action: #selector(floatingButtonTapped), for: .touchUpInside)
        
        view.addSubview(floatingButton)
        
        // レイアウト設定（右上に配置）
        NSLayoutConstraint.activate([
            floatingButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            floatingButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            floatingButton.heightAnchor.constraint(equalToConstant: 36),
            floatingButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }
    
    private func updateFloatingButtonAppearance() {
        if viewModel.isSelectionMode {
            floatingButton.setTitle(NSLocalizedString("Done", bundle: .module, comment: ""), for: .normal)
        } else {
            floatingButton.setTitle(NSLocalizedString("Edit", bundle: .module, comment: ""), for: .normal)
        }
        
        // カプセル型の背景スタイル
        floatingButton.backgroundColor = UIColor.systemGray5
        floatingButton.setTitleColor(.label, for: .normal)
        floatingButton.layer.cornerRadius = 18
        floatingButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        // 影を追加
        floatingButton.layer.shadowColor = UIColor.black.cgColor
        floatingButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        floatingButton.layer.shadowRadius = 4
        floatingButton.layer.shadowOpacity = 0.1
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
    
    @objc private func floatingButtonTapped() {
        if viewModel.isSelectionMode {
            viewModel.exitSelectionMode()
        } else {
            viewModel.enterSelectionMode()
        }
    }
}
