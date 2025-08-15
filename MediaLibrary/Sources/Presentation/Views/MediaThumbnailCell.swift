import MediaLibraryDomain
import SwiftUI
import UIKit

/// メディアサムネイル表示用のUICollectionViewCell
final class MediaThumbnailCell: UICollectionViewCell {
    // MARK: - Properties

    static let identifier = "MediaThumbnailCell"

    private var hostingController: UIHostingController<PhotoThumbnailView>?

    /// Appleサンプル準拠：セル再利用時の問題を防ぐため
    var representedAssetIdentifier: String!

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.backgroundColor = .clear
    }

    // MARK: - Configuration

    func configure(with media: Media, thumbnail: Media.Thumbnail?) {
        // Appleサンプル準拠：representedAssetIdentifierを設定
        representedAssetIdentifier = media.id.value

        // UIHostingControllerの再利用を最適化
        if hostingController == nil {
            setupHostingController()
        }

        // SwiftUIビューを作成（軽量化）
        let thumbnailView = PhotoThumbnailView(
            media: media,
            thumbnail: thumbnail,
            size: CGSize(width: 200, height: 200)
        )

        // ビューの更新のみ行う（再作成を避ける）
        hostingController?.rootView = thumbnailView
    }

    private func setupHostingController() {
        // 初回のみUIHostingControllerを作成
        let initialView = PhotoThumbnailView(
            media: nil,
            thumbnail: nil,
            size: CGSize(width: 200, height: 200)
        )

        let hostingController = UIHostingController(rootView: initialView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        self.hostingController = hostingController

        contentView.addSubview(hostingController.view)

        // レイアウト制約を設定（一度のみ）
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()

        // Appleサンプル準拠：軽量化のため削除処理は行わない
        // UIHostingControllerは再利用し、新しいビューの設定のみ行う
        representedAssetIdentifier = nil
    }
}
