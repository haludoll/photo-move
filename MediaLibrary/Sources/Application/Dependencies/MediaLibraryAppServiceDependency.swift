import Dependencies
import Foundation

/// MediaLibraryAppServiceのDependency定義
extension DependencyValues {
    package var mediaLibraryAppService: MediaLibraryAppService {
        get { self[MediaLibraryAppServiceKey.self] }
        set { self[MediaLibraryAppServiceKey.self] = newValue }
    }
}

private struct MediaLibraryAppServiceKey: DependencyKey {
    static let liveValue = MediaLibraryAppService()
    static let testValue = MediaLibraryAppService()
}