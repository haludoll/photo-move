import SwiftUI

/// メディアライブラリ画面（Public API）
public struct MediaLibraryView: View {
    public init() {}

    public var body: some View {
        MediaLibraryViewControllerWrapper()
            .ignoresSafeArea()
    }
}
