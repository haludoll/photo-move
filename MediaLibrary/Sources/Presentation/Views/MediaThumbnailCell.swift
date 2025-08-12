import MediaLibraryDomain
import SwiftUI
import UIKit

/// メディアサムネイル表示用のUICollectionViewCell
final class MediaThumbnailCell: UICollectionViewCell {
    // MARK: - Properties

    static let identifier = "MediaThumbnailCell"

    private var hostingController: UIHostingController<PhotoThumbnailView>?

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
        // 既存のhostingControllerをクリア
        hostingController?.view.removeFromSuperview()

        // SwiftUIビューを作成
        let thumbnailView = PhotoThumbnailView(
            media: media,
            thumbnail: thumbnail,
            size: CGSize(width: 200, height: 200)
        )

        // UIHostingControllerでSwiftUIビューを埋め込み
        let hostingController = UIHostingController(rootView: thumbnailView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        self.hostingController = hostingController

        contentView.addSubview(hostingController.view)

        // レイアウト制約を設定
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

        // HostingControllerをクリア
        hostingController?.view.removeFromSuperview()
        hostingController = nil
    }
}
