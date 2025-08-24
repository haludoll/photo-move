import MediaLibraryDependencyInjection
import SwiftUI
import UIKit

/// MediaLibraryViewControllerをSwiftUIでラップする内部実装
struct MediaLibraryViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> UINavigationController {
        let viewController = MediaLibraryViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        
        // ナビゲーションバーの外観設定
        navigationController.navigationBar.prefersLargeTitles = true
        
        return navigationController
    }

    func updateUIViewController(_: UINavigationController, context _: Context) {
        // 必要に応じて更新処理を実装
    }
}
