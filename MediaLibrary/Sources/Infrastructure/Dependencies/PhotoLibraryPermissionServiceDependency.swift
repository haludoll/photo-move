import Dependencies
import Domain
import Foundation

package extension DependencyValues {
    var photoLibraryPermissionService: any PhotoLibraryPermissionService {
        get { self[PhotoLibraryPermissionServiceKey.self] }
        set { self[PhotoLibraryPermissionServiceKey.self] = newValue }
    }
}

private struct PhotoLibraryPermissionServiceKey: DependencyKey {
    static let liveValue: any PhotoLibraryPermissionService = {
        #if os(iOS)
            return PhotoLibraryPermissionServiceImpl()
        #else
            fatalError("PhotoLibraryPermissionServiceImpl requires iOS")
        #endif
    }()

    static let testValue: any PhotoLibraryPermissionService = MockPermissionService()
}

/// テスト用のMockPermissionService
private struct MockPermissionService: PhotoLibraryPermissionService {
    func checkPermissionStatus() -> PhotoLibraryPermissionStatus {
        return .authorized
    }

    func requestPermission() async -> PhotoLibraryPermissionStatus {
        return .authorized
    }
}