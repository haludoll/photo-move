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
│   ├── Views/            # SwiftUI Views
│   └── ViewModels/       # MVVM ViewModels
├── Application/          # アプリケーション層
│   └── Services/         # アプリケーションサービス
├── Domain/               # ドメイン層
│   ├── Entities/         # エンティティ
│   ├── ValueObjects/     # 値オブジェクト
│   ├── Aggregates/       # 集約
│   └── Repositories/     # リポジトリインターフェース
└── Infrastructure/       # インフラストラクチャ層
    ├── Repositories/     # リポジトリ実装
    └── External/         # 外部API、PhotoKit等
```

## 依存関係

MediaLibraryは以下の依存関係を持ちます：

- **AssetTransferContext**: 選択されたメディアの転送機能を利用

## 詳細仕様

詳細な仕様については、`docs/` ディレクトリ内の各種ドキュメントを参照してください。
