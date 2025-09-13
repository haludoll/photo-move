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

    private let mediaLibraryViewModel: MediaLibraryViewModel
    private var mediaLibraryCollectionView: MediaLibraryCollectionView!
    private var cancellables = Set<AnyCancellable>()
    private var previousSelectedIDs: Set<Media.ID> = []

    // MARK: - Initialization

    init(mediaLibraryViewModel: MediaLibraryViewModel) {
        self.mediaLibraryViewModel = mediaLibraryViewModel
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
            await mediaLibraryViewModel.loadPhotos()
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
        mediaLibraryCollectionView = MediaLibraryCollectionView(viewModel: mediaLibraryViewModel)
        mediaLibraryCollectionView.translatesAutoresizingMaskIntoConstraints = false

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
        mediaLibraryViewModel.$media
            .receive(on: DispatchQueue.main)
            .sink { [weak self] media in
                self?.mediaLibraryCollectionView.createInitialSnapshot(media)
            }
            .store(in: &cancellables)

        // エラーの監視はSwiftUIで行うため削除

        // サムネイルの読み込み監視
        mediaLibraryViewModel.thumbnailLoadedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mediaID in
                self?.mediaLibraryCollectionView.updateThumbnail(from: mediaID)
            }
            .store(in: &cancellables)

        // 選択モードの監視
        mediaLibraryViewModel.$isSelectionMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSelectionMode in
                self?.setEditing(isSelectionMode, animated: true)
            }
            .store(in: &cancellables)

        // 選択状態の監視
        mediaLibraryViewModel.$selectedMediaIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentSelectedIDs in
                guard let self else { return }
                let added = currentSelectedIDs.subtracting(self.previousSelectedIDs)
                let removed = self.previousSelectedIDs.subtracting(currentSelectedIDs)

                // 選択状態が変更されたセルの表示を直接更新
                for mediaID in added.union(removed) {
                    self.mediaLibraryCollectionView.updateSelectionStatus(from: mediaID)
                }

                self.previousSelectedIDs = currentSelectedIDs
            }
            .store(in: &cancellables)
    }


    // MARK: - Editing Mode

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        mediaLibraryCollectionView.collectionView.isEditing = editing
    }
}

