import SwiftUI
import UIKit

extension UIViewController {
    /// SwiftUIビューをUIViewControllerに埋め込むためのヘルパーメソッド
    /// - Parameters:
    ///   - swiftUIView: 埋め込むSwiftUIビュー
    ///   - constraints: レイアウト制約を設定するクロージャ
    /// - Returns: SwiftUIビューをホストするUIHostingController
    @discardableResult
    func embed<Content: View>(
        _ swiftUIView: Content,
        constraints: (UIView, UIView) -> [NSLayoutConstraint]
    ) -> UIHostingController<Content> {
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // 制約を適用
        let layoutConstraints = constraints(hostingController.view, view)
        NSLayoutConstraint.activate(layoutConstraints)
        
        return hostingController
    }
    
    /// SwiftUIビューをUIViewControllerの指定位置に埋め込むためのヘルパーメソッド
    /// - Parameters:
    ///   - swiftUIView: 埋め込むSwiftUIビュー
    ///   - position: 配置位置
    ///   - margins: マージン設定
    /// - Returns: SwiftUIビューをホストするUIHostingController
    @discardableResult
    func embed<Content: View>(
        _ swiftUIView: Content,
        at position: SwiftUIPosition,
        margins: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    ) -> UIHostingController<Content> {
        return embed(swiftUIView) { hostingView, containerView in
            position.constraints(for: hostingView, in: containerView, margins: margins)
        }
    }
}

/// SwiftUIビューの配置位置を定義する列挙型
enum SwiftUIPosition {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing
    case center
    case fullScreen
    
    /// 指定された位置に対応するAuto Layout制約を生成
    @MainActor func constraints(
        for hostingView: UIView,
        in containerView: UIView,
        margins: UIEdgeInsets
    ) -> [NSLayoutConstraint] {
        let safeArea = containerView.safeAreaLayoutGuide
        
        switch self {
        case .topLeading:
            return [
                hostingView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: margins.top),
                hostingView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: margins.left)
            ]
        case .topTrailing:
            return [
                hostingView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: margins.top),
                hostingView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -margins.right)
            ]
        case .bottomLeading:
            return [
                hostingView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -margins.bottom),
                hostingView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: margins.left)
            ]
        case .bottomTrailing:
            return [
                hostingView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -margins.bottom),
                hostingView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -margins.right)
            ]
        case .center:
            return [
                hostingView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
                hostingView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor)
            ]
        case .fullScreen:
            return [
                hostingView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: margins.top),
                hostingView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: margins.left),
                hostingView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -margins.right),
                hostingView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -margins.bottom)
            ]
        }
    }
}
