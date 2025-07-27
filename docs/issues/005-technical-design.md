# Issue #5: 技術的詳細設計

## 概要
写真ライブラリから写真を取得して一覧で表示する機能の技術的詳細設計

## アーキテクチャ層の実装

### 1. Presentation層

#### PhotoLibraryView
```swift
struct PhotoLibraryView: View {
    @StateObject private var viewModel = PhotoLibraryViewModel()
    
    var body: some View {
        // グリッド表示の実装
        LazyVGrid(columns: gridColumns, spacing: 4) {
            ForEach(viewModel.photos) { photo in
                PhotoThumbnailView(photo: photo)
            }
        }
        .onAppear {
            viewModel.loadPhotos()
        }
    }
}
```

#### PhotoLibraryViewModel
```swift
class PhotoLibraryViewModel: ObservableObject {
    @Published var photos: [Media] = []
    @Published var permissionStatus: PhotoLibraryPermission = .notDetermined
    
    private let mediaLibraryService: MediaLibraryService
    
    func loadPhotos() async {
        // アプリケーションサービスを呼び出し
        do {
            photos = try await mediaLibraryService.getPhotos()
        } catch {
            // エラーハンドリング
        }
    }
}
```

### 2. Application層

#### MediaLibraryService
```swift
class MediaLibraryService {
    private let mediaRepository: MediaRepository
    private let thumbnailRepository: ThumbnailRepository
    
    func getPhotos() async throws -> [Media] {
        // 権限チェック
        let permission = await checkPermission()
        guard permission == .authorized else {
            throw MediaError.permissionDenied
        }
        
        // メディア取得
        let photos = try await mediaRepository.getAllMedia()
        
        // サムネイル生成・取得
        for photo in photos {
            try await thumbnailRepository.getThumbnail(for: photo.id)
        }
        
        return photos
    }
    
    private func checkPermission() async -> PhotoLibraryPermission {
        // PhotoKit権限チェック実装
    }
}
```

### 3. Domain層

#### Media Entity
```swift
struct Media: Identifiable {
    let id: MediaID
    let type: MediaType
    let metadata: MediaMetadata
    let filePath: String
    
    // 不変条件の検証
    init(id: MediaID, type: MediaType, metadata: MediaMetadata, filePath: String) throws {
        guard !filePath.isEmpty else {
            throw MediaError.invalidFilePath
        }
        
        self.id = id
        self.type = type
        self.metadata = metadata
        self.filePath = filePath
    }
}
```

#### MediaID Value Object
```swift
struct MediaID: Hashable, Identifiable {
    let value: String
    
    var id: String { value }
    
    init(_ value: String) throws {
        guard !value.isEmpty else {
            throw MediaError.invalidMediaID
        }
        self.value = value
    }
}
```

#### MediaType Enum
```swift
enum MediaType: String, CaseIterable {
    case photo = "photo"
}
```

#### MediaMetadata Value Object
```swift
struct MediaMetadata {
    let format: MediaFormat
    let capturedAt: Date
    
    init(format: MediaFormat, capturedAt: Date) {
        self.format = format
        self.capturedAt = capturedAt
    }
}
```

#### MediaFormat Enum
```swift
enum MediaFormat: String, CaseIterable {
    case jpeg = "JPEG"
    case png = "PNG"
    case heic = "HEIC"
}
```

#### Thumbnail Value Object
```swift
struct Thumbnail {
    let mediaID: MediaID
    let imageData: Data
    let size: CGSize
    
    init(mediaID: MediaID, imageData: Data, size: CGSize) throws {
        guard !imageData.isEmpty else {
            throw MediaError.invalidThumbnailData
        }
        
        self.mediaID = mediaID
        self.imageData = imageData
        self.size = size
    }
}
```

#### PhotoLibraryPermission Enum
```swift
enum PhotoLibraryPermission: String, CaseIterable {
    case notDetermined = "notDetermined"
    case authorized = "authorized"
    case denied = "denied"
}
```

#### MediaError Domain Error
```swift
enum MediaError: Error, LocalizedError {
    case invalidMediaID
    case invalidFilePath
    case invalidThumbnailData
    case permissionDenied
    case mediaNotFound
    case unsupportedFormat
    case thumbnailGenerationFailed
    case mediaLoadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidMediaID:
            return "無効なメディアIDです"
        case .invalidFilePath:
            return "無効なファイルパスです"
        case .invalidThumbnailData:
            return "無効なサムネイルデータです"
        case .permissionDenied:
            return "写真ライブラリへのアクセス権限がありません"
        case .mediaNotFound:
            return "メディアが見つかりません"
        case .unsupportedFormat:
            return "サポートされていないファイル形式です"
        case .thumbnailGenerationFailed:
            return "サムネイル生成に失敗しました"
        case .mediaLoadFailed:
            return "メディアの読み込みに失敗しました"
        }
    }
}
```

#### Repository Interfaces
```swift
protocol MediaRepository {
    func getAllMedia() async throws -> [Media]
    func getMedia(by id: MediaID) async throws -> Media?
}

protocol ThumbnailRepository {
    func getThumbnail(for mediaID: MediaID) async throws -> Thumbnail
    func saveThumbnail(_ thumbnail: Thumbnail) async throws
}
```

### 4. Infrastructure層

#### PhotoKitMediaRepository
```swift
class PhotoKitMediaRepository: MediaRepository {
    func getAllMedia() async throws -> [Media] {
        // PhotoKitを使用してPHAssetを取得
        let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
        
        var mediaList: [Media] = []
        
        fetchResult.enumerateObjects { (asset, index, stop) in
            do {
                let media = try self.convertToMedia(asset)
                mediaList.append(media)
            } catch {
                // ログ出力してスキップ
            }
        }
        
        return mediaList
    }
    
    private func convertToMedia(_ asset: PHAsset) throws -> Media {
        let id = try MediaID(asset.localIdentifier)
        let type = MediaType.photo
        let format = MediaFormat.jpeg // 実際はasset.mediaSubtypesから判定
        let metadata = MediaMetadata(
            format: format,
            capturedAt: asset.creationDate ?? Date()
        )
        
        return try Media(
            id: id,
            type: type,
            metadata: metadata,
            filePath: asset.localIdentifier
        )
    }
}
```

#### PhotoKitThumbnailRepository
```swift
class PhotoKitThumbnailRepository: ThumbnailRepository {
    private let imageManager = PHImageManager.default()
    private let thumbnailSize = CGSize(width: 150, height: 150)
    
    func getThumbnail(for mediaID: MediaID) async throws -> Thumbnail {
        // PHAssetを取得
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [mediaID.value],
            options: nil
        )
        
        guard let asset = fetchResult.firstObject else {
            throw MediaError.mediaNotFound
        }
        
        // サムネイル画像を生成
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = false
        
        return try await withCheckedThrowingContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: thumbnailSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                guard let image = image,
                      let data = image.pngData() else {
                    continuation.resume(throwing: MediaError.thumbnailGenerationFailed)
                    return
                }
                
                do {
                    let thumbnail = try Thumbnail(
                        mediaID: mediaID,
                        imageData: data,
                        size: self.thumbnailSize
                    )
                    continuation.resume(returning: thumbnail)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
```

## 依存性注入

### DIContainer
```swift
class DIContainer {
    static let shared = DIContainer()
    
    lazy var mediaRepository: MediaRepository = PhotoKitMediaRepository()
    lazy var thumbnailRepository: ThumbnailRepository = PhotoKitThumbnailRepository()
    
    lazy var mediaLibraryService: MediaLibraryService = MediaLibraryService(
        mediaRepository: mediaRepository,
        thumbnailRepository: thumbnailRepository
    )
}
```

## パッケージ構成

```
MediaLibrary/
├── Presentation/
│   ├── Views/
│   │   ├── PhotoLibraryView.swift
│   │   └── PhotoThumbnailView.swift
│   └── ViewModels/
│       └── PhotoLibraryViewModel.swift
├── Application/
│   └── Services/
│       └── MediaLibraryService.swift
├── Domain/
│   ├── Entities/
│   │   └── Media.swift
│   ├── ValueObjects/
│   │   ├── MediaID.swift
│   │   ├── MediaType.swift
│   │   ├── MediaMetadata.swift
│   │   ├── MediaFormat.swift
│   │   ├── Thumbnail.swift
│   │   └── PhotoLibraryPermission.swift
│   ├── Aggregates/
│   │   └── (Media集約はEntityと同じファイル)
│   └── Repositories/
│       ├── MediaRepository.swift
│       └── ThumbnailRepository.swift
├── Infrastructure/
│   ├── Repositories/
│   │   ├── PhotoKitMediaRepository.swift
│   │   └── PhotoKitThumbnailRepository.swift
│   └── External/
│       └── (PhotoKit関連のユーティリティ)
└── Dependency/
    └── DIContainer.swift
```

## 実装順序

1. **Domain層の実装**
   - Value Objects (MediaID, MediaType, MediaMetadata, MediaFormat, Thumbnail, PhotoLibraryPermission)
   - Entity (Media)
   - Domain Error (MediaError)
   - Repository Interfaces

2. **Infrastructure層の実装**
   - PhotoKitMediaRepository
   - PhotoKitThumbnailRepository

3. **Application層の実装**
   - MediaLibraryService

4. **Presentation層の実装**
   - PhotoLibraryViewModel
   - PhotoLibraryView
   - PhotoThumbnailView

5. **依存性注入**
   - DIContainer

## テスト戦略

### 単体テスト
- Domain層: 値オブジェクトの制約テスト、エンティティの不変条件テスト
- Application層: MediaLibraryServiceのビジネスロジックテスト
- Infrastructure層: リポジトリの実装テスト（モック使用）

### 統合テスト
- ViewModelとServiceの連携テスト
- 実際のPhotoKitを使用した結合テスト