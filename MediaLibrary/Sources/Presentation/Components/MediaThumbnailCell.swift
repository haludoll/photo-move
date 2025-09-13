import MediaLibraryDomain
import SwiftUI
import UIKit

/// メディアサムネイル表示用のUICollectionViewCell
final class MediaThumbnailCell: UICollectionViewCell {
    // MARK: - Properties

    static let identifier = "MediaThumbnailCell"

    private var hostingController: UIHostingController<PhotoThumbnailView>?
    private var imageView: UIImageView!
    private var checkmarkView: UIImageView!
    private var overlayView: UIView!

    /// セル再利用時に誤った画像が表示されるのを防ぐ
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
        setupImageView()
        setupOverlayView()
        setupCheckmarkView()
    }

    // MARK: - Cell Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        representedAssetIdentifier = nil
        imageView.image = nil
        checkmarkView.isHidden = true
        overlayView.isHidden = true
    }

    // MARK: - Configuration

    func configure(with mediaID: Media.ID, thumbnail: Media.Thumbnail?, isSelected: Bool = false) {
        representedAssetIdentifier = mediaID.value
        updateThumbnail(with: thumbnail)
        updateCheckmark(isSelected: isSelected)
    }

    func updateThumbnail(with thumbnail: Media.Thumbnail?) {
        if let thumbnail {
            imageView.image = ThumbnailConverter.createImage(from: thumbnail)
        } else {
            imageView.image = nil
        }
    }

    func updateCheckmark(isSelected: Bool) {
        checkmarkView.isHidden = !isSelected
        overlayView.isHidden = !isSelected
    }

    private func setupImageView() {
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

    private func setupOverlayView() {
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.isHidden = true

        self.overlayView = overlayView
        contentView.addSubview(overlayView)

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
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
            checkmarkView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            checkmarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            checkmarkView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkView.heightAnchor.constraint(equalToConstant: 24),
        ])
    }
}
