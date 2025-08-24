import MediaLibraryDomain
import SwiftUI
import UIKit

/// メディアサムネイル表示用のUICollectionViewCell
final class MediaThumbnailCell: UICollectionViewCell {
    // MARK: - Properties

    static let identifier = "MediaThumbnailCell"

    private var hostingController: UIHostingController<PhotoThumbnailView>?
    private var imageView: UIImageView?
    private var checkmarkView: UIImageView?

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

    func configure(with media: Media, thumbnail: Media.Thumbnail?, isSelected: Bool = false) {
        // Appleサンプル準拠：representedAssetIdentifierを設定
        representedAssetIdentifier = media.id.value

        // 画像表示の設定
        if imageView == nil {
            setupImageView()
        }

        if let thumbnail = thumbnail {
            imageView?.image = thumbnail.image
        } else {
            imageView?.image = nil
        }
        
        // チェックマーク表示の設定
        updateCheckmark(isSelected: isSelected)
    }
    
    private func updateCheckmark(isSelected: Bool) {
        if isSelected {
            if checkmarkView == nil {
                setupCheckmarkView()
            }
            checkmarkView?.isHidden = false
        } else {
            checkmarkView?.isHidden = true
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
    
    private func setupCheckmarkView() {
        let checkmarkView = UIImageView()
        checkmarkView.image = UIImage(systemName: "checkmark.circle.fill")
        checkmarkView.tintColor = .systemBlue
        checkmarkView.backgroundColor = .white
        checkmarkView.layer.cornerRadius = 12
        checkmarkView.clipsToBounds = true
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false
        checkmarkView.isHidden = true
        
        self.checkmarkView = checkmarkView
        contentView.addSubview(checkmarkView)
        
        NSLayoutConstraint.activate([
            checkmarkView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            checkmarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            checkmarkView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkView.heightAnchor.constraint(equalToConstant: 24)
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
        checkmarkView?.isHidden = true
        representedAssetIdentifier = nil
    }
}
