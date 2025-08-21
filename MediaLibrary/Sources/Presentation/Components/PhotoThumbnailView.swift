import MediaLibraryDomain
import SwiftUI
import UIKit

/// 写真サムネイルビュー（SwiftUI）
struct PhotoThumbnailView: View {
    let media: Media?
    let thumbnail: Media.Thumbnail?
    let size: CGSize

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Group {
                    if let thumbnail = thumbnail,
                       let uiImage = UIImage(data: thumbnail.imageData)
                    {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .scaleEffect(0.5)
                            )
                    }
                }
            )
            .clipped()
    }
}
