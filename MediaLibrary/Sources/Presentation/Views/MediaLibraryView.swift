import MediaLibraryDependencyInjection
import MediaLibraryDomain
import SwiftUI

/// メディアライブラリ画面（Public API）
public struct MediaLibraryView: View {
    @StateObject private var mediaLibraryViewModel = MediaLibraryViewModel(mediaLibraryService: AppDependencies.mediaLibraryAppService)

    public init() {}

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            MediaLibraryViewControllerWrapper(mediaLibraryViewModel: mediaLibraryViewModel)
                .ignoresSafeArea()

            MediaSelectionModeButton(isSelectionMode: mediaLibraryViewModel.isSelectionMode) {
                mediaLibraryViewModel.toggleSelectionMode()
            }
            .padding(.all)
        }
        .alert("Error", isPresented: .constant(mediaLibraryViewModel.error != nil)) {
            Button("OK") {
                mediaLibraryViewModel.clearError()
            }
        } message: {
            if let error = mediaLibraryViewModel.error {
                Text(error.localizedMessage)
            }
        }
    }
}

#Preview {
    MediaLibraryView()
}
