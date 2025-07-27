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
        
        _ = try view.inspect().navigationView()
    }
    
    @Test("空状態 - 基本構造確認")
    func emptyStateBasicStructure() throws {
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
        
        _ = try view.inspect().navigationView()
    }
    
    @Test("ローディング状態 - 基本構造確認")
    func loadingStateBasicStructure() throws {
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
        
        _ = try view.inspect().navigationView()
    }
    
    @Test("メディアあり状態 - 基本構造確認")
    func contentStateBasicStructure() throws {
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
        
        _ = try view.inspect().navigationView()
    }
    
    @Test("エラー状態 - 基本構造確認")
    func errorStateBasicStructure() throws {
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
        
        _ = try view.inspect().navigationView()
    }
}