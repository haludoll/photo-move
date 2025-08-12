import MediaLibraryDependencyInjection
import MediaLibraryDomain
import SwiftUI
import UIKit

/// メディアライブラリ画面（UIKitをSwiftUIでラップ）
public struct MediaLibraryView: UIViewControllerRepresentable {
    // MARK: - UIViewControllerRepresentable

    public init() {}

    public func makeUIViewController(context _: Context) -> MediaLibraryViewController {
        let viewModel = MediaLibraryViewModel(mediaLibraryService: AppDependencies.mediaLibraryAppService)
        return MediaLibraryViewController(viewModel: viewModel)
    }

    public func updateUIViewController(_: MediaLibraryViewController, context _: Context) {
        // 必要に応じて更新処理を実装
    }
}
