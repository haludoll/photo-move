import Foundation
import MediaLibraryDomain

/// DiffableDataSource用のHashableなメディアアイテム
package struct MediaItem: Hashable {
    // MARK: - Properties

    package let media: Media
    package let isSelected: Bool

    // MARK: - Initialization

    package init(media: Media, isSelected: Bool = false) {
        self.media = media
        self.isSelected = isSelected
    }

    // MARK: - Hashable

    package func hash(into hasher: inout Hasher) {
        // MediaのIDのみでハッシュ化（選択状態は含めない）
        hasher.combine(media.id)
    }

    package static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        // MediaのIDのみで比較（選択状態の変更は差分として検知される）
        return lhs.media.id == rhs.media.id && lhs.isSelected == rhs.isSelected
    }
}

/// DiffableDataSource用のセクション識別子
package enum MediaSection: CaseIterable, Hashable {
    case photos

    package var title: String {
        switch self {
        case .photos:
            return "Photos"
        }
    }
}
