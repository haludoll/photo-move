import Domain
import Foundation
import Photos

/// PhotoKitを使用した写真ライブラリ権限管理の実装
package struct PhotoLibraryPermissionServiceImpl: PhotoLibraryPermissionService {
    package init() {}

    package func checkPermissionStatus() -> PhotoLibraryPermissionStatus {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    package func requestPermission() async -> PhotoLibraryPermissionStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        switch status {
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }
}
