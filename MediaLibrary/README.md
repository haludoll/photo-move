# MediaLibrary

## 概要

MediaLibraryは、写真・動画の管理、閲覧、検索機能を提供するコンテキストです。ユーザーが写真を見る、選ぶ、整理するためのドメインを担当します。

## 主な責務

- **写真・動画の一覧表示**: デバイスのストレージ内のメディアライブラリを整理された形で表示
- **サムネイル管理**: 効率的なサムネイル生成・キャッシング
- **検索・フィルタリング機能**: 日付、場所、メタデータによる絞り込み
- **メタデータ管理**: 撮影日時、場所、サイズ等の情報管理
- **メディア選択機能**: 写真・動画の選択とマルチ選択

## 主要な概念

- **Media**: 写真・動画エンティティ
- **MediaMetadata**: メタデータ（撮影日時、場所、サイズ等）
- **MediaFilter**: 検索・フィルター条件
- **MediaSelection**: 選択されたメディアの管理

## アーキテクチャ

本パッケージは以下のDDDに基づく層構造を持ちます：

```
MediaLibrary/
├── Presentation/          # プレゼンテーション層
│   └── ViewModels/       # MVVM ViewModels (ObservableObject)
├── Application/          # アプリケーション層
│   └── Services/         # アプリケーションサービス (struct)
├── Domain/               # ドメイン層
│   ├── Entities/         # エンティティ
│   ├── ValueObjects/     # 値オブジェクト
│   ├── Services/         # ドメインサービス
│   ├── Repositories/     # リポジトリプロトコル
│   └── Errors/          # ドメインエラー
├── Infrastructure/       # インフラストラクチャ層
│   ├── Repositories/     # リポジトリ実装 (struct)
│   └── Services/        # ドメインサービス実装 (struct)
└── DependencyInjection/  # 依存性注入層 (Composition Root)
    ├── AppContainer.swift # 本番用依存関係管理
    └── AppFactory.swift  # ファクトリーパターン
```

### 依存性注入アーキテクチャ

- **Composition Rootパターン**: `AppDependencies`が全体の依存関係を管理
- **Protocol-based DI**: swift-dependenciesの代わりにプロトコルベースの依存性注入
- **struct-based services**: ステートレスなサービスはstructで実装
- **静的プロパティ**: 各依存関係は`static let`プロパティで定義
- **Swift 6対応**: 明示的な`any`修飾子を使用

## 技術仕様

### 対応プラットフォーム
- **iOS 15+**: iOS専用パッケージ
- **Swift 6**: Swift 6 strict concurrency対応

### テストフレームワーク
- **swift-testing**: 新しいテストフレームワークを使用
- **@Test属性**: XCTestの代わりにswift-testingの@Test属性
- **#expect**: XCTAssertの代わりに#expectマクロ

### コードフォーマット
- **swift-format**: 自動コードフォーマットツール

## 依存関係

MediaLibraryは以下の依存関係を持ちます：

- **AssetTransferContext**: 選択されたメディアの転送機能を利用（将来実装予定）

## 詳細仕様

詳細な仕様については、`docs/` ディレクトリ内の各種ドキュメントを参照してください。
