import Dependencies
import Domain
import Foundation
import Infrastructure

@available(iOS 15.0, macOS 11.0, *)
package extension DependencyValues {
    var photoLibraryPermissionService: any PhotoLibraryPermissionService {
        get { self[PhotoLibraryPermissionServiceKey.self] }
        set { self[PhotoLibraryPermissionServiceKey.self] = newValue }
    }
}

@available(iOS 15.0, macOS 11.0, *)
private struct PhotoLibraryPermissionServiceKey: DependencyKey {
    static let liveValue: any PhotoLibraryPermissionService = PhotoLibraryPermissionServiceImpl()

    static let testValue: any PhotoLibraryPermissionService = MockPermissionService()
}

/// テスト用のMockPermissionService
@available(iOS 15.0, macOS 11.0, *)
private struct MockPermissionService: PhotoLibraryPermissionService {
    func checkPermissionStatus() -> PhotoLibraryPermissionStatus {
        return .authorized
    }

    func requestPermission() async -> PhotoLibraryPermissionStatus {
        return .authorized
    }
}
