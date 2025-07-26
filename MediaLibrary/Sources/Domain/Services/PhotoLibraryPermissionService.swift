import Foundation

/// フォトライブラリの権限管理を抽象化するプロトコル
package protocol PhotoLibraryPermissionService: Sendable {
    /// 現在の権限状態を取得する
    func checkPermissionStatus() -> PhotoLibraryPermissionStatus
    
    /// 権限を要求する
    func requestPermission() async -> PhotoLibraryPermissionStatus
}