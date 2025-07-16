# MediaLibrary - ドメインモデル設計書

## 概要

MediaLibraryContextのドメインモデルを、ドメイン駆動設計の原則に基づいて設計します。

## エンティティ (Entities)

### Media
写真・動画を表現するルートエンティティ

```swift
struct Media {
    let id: MediaID
    let type: MediaType
    let filePath: String
    let metadata: MediaMetadata
    let createdAt: Date
    let modifiedAt: Date
}
```

**特徴**:
- 一意の識別子を持つ
- 不変オブジェクト
- ファイルシステムとの連携を抽象化

## 値オブジェクト (Value Objects)

### MediaID
メディアの一意識別子

```swift
struct MediaID {
    let value: String
    
    init(_ value: String) throws {
        guard !value.isEmpty else {
            throw MediaError.invalidID
        }
        self.value = value
    }
}
```

### MediaType
メディアの種類を表現

```swift
enum MediaType: String, CaseIterable {
    case photo = "photo"
    case video = "video"
}
```

### MediaMetadata
メディアのメタデータを表現

```swift
struct MediaMetadata {
    let fileSize: FileSize
    let resolution: Resolution?
    let location: GeographicLocation?
    let format: MediaFormat
}
```

### FileSize
ファイルサイズを表現

```swift
struct FileSize {
    let bytes: Int64
    
    var megabytes: Double {
        return Double(bytes) / 1_048_576
    }
}
```

### Resolution
解像度を表現

```swift
struct Resolution {
    let width: Int
    let height: Int
    
    var aspectRatio: Double {
        return Double(width) / Double(height)
    }
}
```

### GeographicLocation
地理的位置を表現

```swift
struct GeographicLocation {
    let latitude: Double
    let longitude: Double
    let altitude: Double?
}
```

### MediaFormat
メディアフォーマットを表現

```swift
enum MediaFormat: String, CaseIterable {
    // 写真フォーマット
    case jpeg = "jpeg"
    case png = "png"
    case heic = "heic"
    
    // 動画フォーマット
    case mp4 = "mp4"
    case mov = "mov"
    case avi = "avi"
    
    var isPhotoFormat: Bool {
        return [.jpeg, .png, .heic].contains(self)
    }
    
    var isVideoFormat: Bool {
        return [.mp4, .mov, .avi].contains(self)
    }
}
```

### Thumbnail
サムネイルを表現

```swift
struct Thumbnail {
    let mediaID: MediaID
    let imageData: Data
    let size: ThumbnailSize
    let createdAt: Date
}
```

### ThumbnailSize
サムネイルサイズを表現

```swift
enum ThumbnailSize {
    case small  // 50x50
    case medium // 150x150
    case large  // 300x300
    
    var dimensions: (width: Int, height: Int) {
        switch self {
        case .small: return (50, 50)
        case .medium: return (150, 150)
        case .large: return (300, 300)
        }
    }
}
```

## 集約 (Aggregates)

### MediaLibrary
メディアライブラリ全体を管理する集約ルート

```swift
class MediaLibrary {
    private var mediaItems: [Media] = []
    private var selection: MediaSelection
    private var currentFilter: MediaFilter?
    
    // メディア管理
    func addMedia(_ media: Media)
    func removeMedia(id: MediaID)
    func getAllMedia() -> [Media]
    func getMedia(id: MediaID) -> Media?
    
    // フィルタリング
    func applyFilter(_ filter: MediaFilter) -> [Media]
    func clearFilter()
    
    // 選択機能
    func selectMedia(id: MediaID) throws
    func deselectMedia(id: MediaID)
    func getSelectedMedia() -> [Media]
    func clearSelection()
    
    // 検索
    func searchMedia(query: String) -> [Media]
}
```

### MediaSelection
メディアの選択状態を管理

```swift
struct MediaSelection {
    private var selectedIDs: Set<MediaID> = []
    let maxSelectionCount: Int?
    
    mutating func select(id: MediaID) throws
    mutating func deselect(id: MediaID)
    mutating func selectAll(ids: [MediaID]) throws
    mutating func clear()
    
    func isSelected(id: MediaID) -> Bool
    var selectedCount: Int { selectedIDs.count }
    func canSelect(id: MediaID) -> Bool
}
```

### MediaFilter
フィルタリング条件を表現

```swift
struct MediaFilter {
    let dateRange: DateRange?
    let mediaTypes: Set<MediaType>
    let fileSizeRange: FileSizeRange?
    let hasLocation: Bool?
    
    func matches(_ media: Media) -> Bool
}
```

### DateRange
日付範囲を表現

```swift
struct DateRange {
    let start: Date
    let end: Date
    
    func contains(_ date: Date) -> Bool {
        return date >= start && date <= end
    }
}
```

### FileSizeRange
ファイルサイズ範囲を表現

```swift
struct FileSizeRange {
    let min: FileSize
    let max: FileSize
    
    func contains(_ size: FileSize) -> Bool {
        return size.bytes >= min.bytes && size.bytes <= max.bytes
    }
}
```

## ドメインサービス (Domain Services)

### MediaLibraryService
メディアライブラリの複合操作を担当

```swift
protocol MediaLibraryService {
    func loadAllMedia() async throws -> [Media]
    func searchMedia(query: String, filter: MediaFilter?) async throws -> [Media]
    func exportSelectedMedia() async throws -> [Media]
}
```

### ThumbnailService
サムネイル生成・管理を担当

```swift
protocol ThumbnailService {
    func generateThumbnail(for media: Media, size: ThumbnailSize) async throws -> Thumbnail
    func getCachedThumbnail(for mediaID: MediaID, size: ThumbnailSize) -> Thumbnail?
    func clearExpiredThumbnails() async
}
```

## リポジトリインターフェース (Repository Interfaces)

### MediaRepository
メディアデータの永続化を抽象化

```swift
protocol MediaRepository {
    func findAll() async throws -> [Media]
    func findByID(_ id: MediaID) async throws -> Media?
    func findByFilter(_ filter: MediaFilter) async throws -> [Media]
    func search(query: String) async throws -> [Media]
    func save(_ media: Media) async throws
    func delete(id: MediaID) async throws
}
```

### ThumbnailRepository
サムネイルデータの永続化を抽象化

```swift
protocol ThumbnailRepository {
    func findByMediaID(_ mediaID: MediaID, size: ThumbnailSize) async throws -> Thumbnail?
    func save(_ thumbnail: Thumbnail) async throws
    func delete(mediaID: MediaID) async throws
    func deleteExpired() async throws
}
```

## ドメインエラー

### MediaError
メディア関連のエラーを表現

```swift
enum MediaError: Error {
    case invalidID
    case mediaNotFound(MediaID)
    case unsupportedFormat(String)
    case fileSizeExceedsLimit(FileSize)
    case selectionLimitExceeded(Int)
    case thumbnailGenerationFailed
    case invalidFilter
}
```

## 集約の境界

```
MediaLibrary (集約ルート)
├── Media (エンティティ)
├── MediaSelection (値オブジェクト)
├── MediaFilter (値オブジェクト)
└── Thumbnail (値オブジェクト)
```

## 不変条件

### MediaLibrary集約
- 選択されたメディアは必ず存在するメディアでなければならない
- 選択数は設定された上限を超えてはならない
- フィルター適用後も選択状態は保持される

### Media エンティティ
- IDは一意でなければならない
- ファイルパスは有効なパスでなければならない

### MediaSelection
- 選択されたIDは重複してはならない
- 選択数は0以上でなければならない
- 上限が設定されている場合は超過してはならない

## 基本的なビジネスルール（暫定）

> **注意**: 以下のルールは暫定的なものであり、実装時に詳細な挙動を定義していきます。

### メディア管理
- メディアは一意の識別子を持つ
- メディアは作成日時を基準にソートされる

### 選択機能
- 選択は一時的な状態である
- 選択可能な上限数は設定可能

### フィルタリング
- 複数のフィルター条件はAND条件で適用される

### サムネイル
- サムネイルは必要に応じて生成される
- サムネイルはキャッシュされる

## 他のコンテキストとの関係

### AssetTransferContext
- MediaSelectionで選択されたメディアを転送対象として提供
- 選択されたメディアのリストを転送コンテキストに渡す