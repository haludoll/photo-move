import SwiftUI
import MediaLibraryDependencyInjection

public struct RootView: View {
    public init() {}

    public var body: some View {
        AppViewFactory.makePhotoLibraryView()
    }
}
