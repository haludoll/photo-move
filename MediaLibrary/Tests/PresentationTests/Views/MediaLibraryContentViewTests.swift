import MediaLibraryDomain
import SwiftUI
import Testing
import ViewInspector
@testable import MediaLibraryPresentation

@MainActor
struct MediaLibraryContentViewTests {
    
    // MARK: - Basic Structure Tests
    
    @Test("基本構造 - NavigationViewが存在する")
    func hasNavigationView() throws {
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
        
        let navigationView = try view.inspect().navigationView()
        #expect(navigationView != nil)
    }
    
    @Test("空状態 - 空のメッセージが表示される")
    func emptyStateShowsEmptyMessage() throws {
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
        
        // NavigationViewが存在することを確認
        let navigationView = try view.inspect().navigationView()
        
        // "No Photos"テキストが含まれていることを確認
        let foundText = try navigationView.find(text: "No Photos")
        #expect(foundText != nil)
    }
    
    @Test("ローディング状態 - ProgressViewが表示される")
    func loadingStateShowsProgressView() throws {
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
        
        let navigationView = try view.inspect().navigationView()
        
        // ProgressViewが存在することを確認
        let progressView = try navigationView.find(ViewType.ProgressView.self)
        #expect(progressView != nil)
    }
    
    @Test("メディアあり状態 - ScrollViewが表示される")
    func contentStateShowsScrollView() throws {
        let testMedia = try [
            Media(
                id: Media.ID("1"),
                type: .photo,
                metadata: Media.Metadata(format: .jpeg, capturedAt: Date()),
                filePath: "test1.jpg"
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
        
        let navigationView = try view.inspect().navigationView()
        
        // ScrollViewが存在することを確認
        let scrollView = try navigationView.find(ViewType.ScrollView.self)
        #expect(scrollView != nil)
    }
    
    @Test("エラー状態 - NavigationViewが存在する")
    func errorStateHasNavigationView() throws {
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
        
        let navigationView = try view.inspect().navigationView()
        #expect(navigationView != nil)
        
        // エラー状態でも基本構造は維持されることを確認
        #expect(true) // NavigationViewが見つかった時点で成功
    }
}