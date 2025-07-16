import Foundation

/// 写真ライブラリへのアクセス権限状態を表現する値オブジェクト
enum PhotoLibraryPermission: String, CaseIterable {
    case notDetermined
    case authorized
    case denied
}
