import Foundation

/// 環境判定に関するユーティリティ
package enum EnvironmentUtils {
    /// SwiftUIプレビュー環境で実行されているかどうかを判定
    package static var isRunningInPreview: Bool {
        #if DEBUG
            return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
            return false
        #endif
    }
}
