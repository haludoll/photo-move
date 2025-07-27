import Foundation
import Presentation
import SwiftUI

/// アプリケーション全体で使用する依存関係へのショートカット
/// AppDependencies へのエイリアスを提供
package typealias App = AppDependencies

/// アプリケーションのメインビューを生成するファクトリ
package enum AppViewFactory {
    /// 写真ライブラリビューを生成する
    @MainActor
    package static func makePhotoLibraryView() -> PhotoLibraryView {
        PhotoLibraryView(viewModel: App.photoLibraryViewModel)
    }
}
