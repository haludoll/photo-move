import MediaLibraryDependencyInjection
import SwiftUI
import UIKit

/// MediaLibraryViewControllerをSwiftUIでラップする内部実装
struct MediaLibraryViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> MediaLibraryViewController {
        let viewController = MediaLibraryViewController()
        // 写真グリッドを全画面に表示して没入感のあるビューアー体験を提供
        viewController.extendedLayoutIncludesOpaqueBars = true
        viewController.edgesForExtendedLayout = .all
        return viewController
    }

    func updateUIViewController(_: MediaLibraryViewController, context _: Context) {
        // 必要に応じて更新処理を実装
    }
}
