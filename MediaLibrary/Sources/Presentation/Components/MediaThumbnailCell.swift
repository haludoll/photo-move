import MediaLibraryDomain
import SwiftUI
import UIKit

/// メディアサムネイル表示用のUICollectionViewCell
final class MediaThumbnailCell: UICollectionViewCell {
    // MARK: - Properties

    static let identifier = "MediaThumbnailCell"

    private var hostingController: UIHostingController<PhotoThumbnailView>?
    private var imageView: UIImageView?

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

    func configure(with mediaItem: MediaItem, thumbnail: Media.Thumbnail?) {
        // Appleサンプル準拠：representedAssetIdentifierを設定
        representedAssetIdentifier = mediaItem.media.id.value

        // 画像表示の設定
        if imageView == nil {
            setupImageView()
        }

        if let thumbnail = thumbnail {
            imageView?.image = thumbnail.image
        } else {
            imageView?.image = nil
        }
    }

    private func setupImageView() {
        // TEST: Appleサンプルと同じUIImageViewを使用
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false

        self.imageView = imageView
        contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
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

        // TEST: UIImageViewのクリア
        imageView?.image = nil
        representedAssetIdentifier = nil
    }
}
