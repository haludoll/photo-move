import UIKit
import MediaLibraryDomain
import Testing
@testable import MediaLibraryPresentation

struct MediaThumbnailCellTests {
    
    @Test("初期状態のテスト")
    @MainActor
    func initialState() async {
        let cell = MediaThumbnailCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        // Assert
        #expect(cell.representedAssetIdentifier == nil)
        #expect(cell.contentView.subviews.isEmpty == false) // setupUI により何かしらのビューが追加される
    }
    
    @Test("メディア設定のテスト")
    @MainActor  
    func configureWithMedia() async {
        let cell = MediaThumbnailCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let media = try! createTestMedia(id: "test-id")
        
        // Act
        cell.configure(with: media, thumbnail: nil, isSelected: false)
        
        // Assert
        #expect(cell.representedAssetIdentifier == "test-id")
    }
    
    @Test("選択状態設定のテスト")
    @MainActor
    func configureWithSelection() async {
        let cell = MediaThumbnailCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let media = try! createTestMedia(id: "test-id")
        
        // Act - 選択状態で設定
        cell.configure(with: media, thumbnail: nil, isSelected: true)
        
        // Assert - チェックマークビューが作成されていることを確認
        let checkmarkView = findCheckmarkView(in: cell.contentView)
        #expect(checkmarkView != nil)
        #expect(checkmarkView?.isHidden == false)
        
        let overlayView = findOverlayView(in: cell.contentView)
        #expect(overlayView != nil)
        #expect(overlayView?.isHidden == false)
    }
    
    @Test("非選択状態設定のテスト")
    @MainActor
    func configureWithoutSelection() async {
        let cell = MediaThumbnailCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let media = try! createTestMedia(id: "test-id")
        
        // Act - まず選択状態にして、その後非選択に
        cell.configure(with: media, thumbnail: nil, isSelected: true)
        cell.configure(with: media, thumbnail: nil, isSelected: false)
        
        // Assert
        let checkmarkView = findCheckmarkView(in: cell.contentView)
        #expect(checkmarkView?.isHidden == true)
        
        let overlayView = findOverlayView(in: cell.contentView)  
        #expect(overlayView?.isHidden == true)
    }
    
    @Test("サムネイル設定のテスト")
    @MainActor
    func configureWithThumbnail() async {
        let cell = MediaThumbnailCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let media = try! createTestMedia(id: "test-id")
        let thumbnail = try! Media.Thumbnail(
            mediaID: media.id,
            imageData: createTestImageData(),
            size: CGSize(width: 100, height: 100)
        )
        
        // Act
        cell.configure(with: media, thumbnail: thumbnail, isSelected: false)
        
        // Assert
        let imageView = findImageView(in: cell.contentView)
        #expect(imageView != nil)
        #expect(imageView?.image != nil)
    }
    
    @Test("セル再利用のテスト")
    @MainActor
    func prepareForReuse() async {
        let cell = MediaThumbnailCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let media = try! createTestMedia(id: "test-id")
        
        // セルを設定
        cell.configure(with: media, thumbnail: nil, isSelected: true)
        #expect(cell.representedAssetIdentifier == "test-id")
        
        // Act - 再利用準備
        cell.prepareForReuse()
        
        // Assert
        #expect(cell.representedAssetIdentifier == nil)
        
        let checkmarkView = findCheckmarkView(in: cell.contentView)
        #expect(checkmarkView?.isHidden != false) // hiddenがtrueまたはnilのはず
        
        let overlayView = findOverlayView(in: cell.contentView)
        #expect(overlayView?.isHidden != false) // hiddenがtrueまたはnilのはず
        
        let imageView = findImageView(in: cell.contentView)
        #expect(imageView?.image == nil)
    }
}

// MARK: - Helper Methods

private func createTestMedia(id: String) throws -> Media {
    return try Media(
        id: Media.ID(id),
        type: .photo,
        metadata: Media.Metadata(
            format: .jpeg,
            capturedAt: Date()
        ),
        filePath: "/path/to/media/\(id).jpg"
    )
}

private func createTestImageData() -> Data {
    // 1x1の白いPNG画像データ
    return Data([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
        0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0x57, 0x63, 0xF8, 0x0F, 0x00, 0x00,
        0x01, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, 0xB4, 0x00, 0x00, 0x00, 0x00,
        0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
    ])
}

// MARK: - View Finding Helpers

private func findImageView(in view: UIView) -> UIImageView? {
    if let imageView = view as? UIImageView {
        return imageView
    }
    
    for subview in view.subviews {
        if let imageView = findImageView(in: subview) {
            return imageView
        }
    }
    
    return nil
}

private func findCheckmarkView(in view: UIView) -> UIImageView? {
    for subview in view.subviews {
        if let imageView = subview as? UIImageView,
           let image = imageView.image,
           image.isEqual(UIImage(systemName: "checkmark.circle.fill")) {
            return imageView
        }
        
        if let checkmarkView = findCheckmarkView(in: subview) {
            return checkmarkView
        }
    }
    
    return nil
}

private func findOverlayView(in view: UIView) -> UIView? {
    for subview in view.subviews {
        // 黒い半透明のオーバーレイビューを探す
        if subview.backgroundColor?.cgColor.alpha == 0.3,
           subview.backgroundColor == UIColor.black.withAlphaComponent(0.3) {
            return subview
        }
        
        if let overlayView = findOverlayView(in: subview) {
            return overlayView
        }
    }
    
    return nil
}