import MediaLibraryDomain
import SwiftUI
import Testing
import ViewInspector
@testable import MediaLibraryPresentation

@MainActor
struct MediaLibraryContentViewTests {
    
    // MARK: - Basic Structure Tests
    
    @Test("基本構造 - NavigationViewのタイトルが正しい")
    func hasCorrectNavigationTitle() throws {
        let view = MediaLibraryContentView(
            media: [],
            isLoading: false,
            error: nil,
            hasError: false,
            thumbnails: [:],
            onLoadPhotos: {},
            onLoadThumbnail: { _, _ in },
            onClearError: {}
        )
        
        let title = try view.inspect().navigationView().navigationBarTitle()
        #expect(title == "Photos")
    }
    
    @Test("空状態 - 空のメッセージが正しく表示される")
    func emptyStateShowsCorrectMessage() throws {
        let view = MediaLibraryContentView(
            media: [],
            isLoading: false,
            error: nil,
            hasError: false,
            thumbnails: [:],
            onLoadPhotos: {},
            onLoadThumbnail: { _, _ in },
            onClearError: {}
        )
        
        // "No Photos"テキストの内容を確認
        let text = try view.inspect().find(text: "No Photos")
        let textValue = try text.string()
        #expect(textValue == "No Photos")
    }
    
    @Test("ローディング状態 - ローディングテキストが正しく表示される")
    func loadingStateShowsCorrectText() throws {
        let view = MediaLibraryContentView(
            media: [],
            isLoading: true,
            error: nil,
            hasError: false,
            thumbnails: [:],
            onLoadPhotos: {},
            onLoadThumbnail: { _, _ in },
            onClearError: {}
        )
        
        // ProgressViewのラベルテキストを確認
        let progressView = try view.inspect().find(ViewType.ProgressView.self)
        let labelText = try progressView.labelView().text().string()
        #expect(labelText.contains("Loading"))
    }
    
    @Test("メディアあり状態 - ForEachの要素数が正しい")
    func contentStateShowsCorrectItemCount() throws {
        let testMedia = try [
            Media(
                id: Media.ID("1"),
                type: .photo,
                metadata: Media.Metadata(format: .jpeg, capturedAt: Date()),
                filePath: "test1.jpg"
            ),
            Media(
                id: Media.ID("2"),
                type: .photo,
                metadata: Media.Metadata(format: .png, capturedAt: Date()),
                filePath: "test2.png"
            )
        ]
        
        let view = MediaLibraryContentView(
            media: testMedia,
            isLoading: false,
            error: nil,
            hasError: false,
            thumbnails: [:],
            onLoadPhotos: {},
            onLoadThumbnail: { _, _ in },
            onClearError: {}
        )
        
        // ForEachの要素数を確認
        let forEach = try view.inspect().find(ViewType.ForEach.self)
        let itemCount = try forEach.count()
        #expect(itemCount == 2)
    }
    
    @Test("エラー状態 - 空状態が表示される")
    func errorStateShowsEmptyState() throws {
        let view = MediaLibraryContentView(
            media: [],
            isLoading: false,
            error: .permissionDenied,
            hasError: true,
            thumbnails: [:],
            onLoadPhotos: {},
            onLoadThumbnail: { _, _ in },
            onClearError: {}
        )
        
        // エラー状態でも空状態のメッセージが表示されることを確認
        let text = try view.inspect().find(text: "No Photos")
        let textValue = try text.string()
        #expect(textValue == "No Photos")
    }
}