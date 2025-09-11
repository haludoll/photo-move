import MediaLibraryDependencyInjection
import SwiftUI
import UIKit

/// MediaLibraryViewControllerをSwiftUIでラップする内部実装
struct MediaLibraryViewControllerWrapper: UIViewControllerRepresentable {
    @ObservedObject var mediaLibraryViewModel: MediaLibraryViewModel

    init(mediaLibraryViewModel: MediaLibraryViewModel) {
        self._mediaLibraryViewModel = .init(wrappedValue: mediaLibraryViewModel)
    }

    func makeUIViewController(context _: Context) -> UINavigationController {
        let viewController = MediaLibraryViewController(mediaLibraryViewModel: mediaLibraryViewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        
        // ナビゲーションバーを非表示に設定
        navigationController.setNavigationBarHidden(true, animated: false)
        
        return navigationController
    }

    func updateUIViewController(_: UINavigationController, context _: Context) {
        // 必要に応じて更新処理を実装
    }
}
