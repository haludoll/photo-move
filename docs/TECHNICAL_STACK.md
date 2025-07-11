# PhotoMove 技術スタック

## 1. 基本方針

### 1.1 アーキテクチャ
- **ドメイン駆動設計（DDD）** を全体に適用
- 境界づけられたコンテキストごとにSwift Packageを分割
- 各コンテキスト内で **MVVM + Layered Architecture** を採用

### 1.2 レイヤー構成
```
PhotoMove
├── [BoundedContext1]Package
│   ├── Presentation層（View）
│   ├── ViewModel層（画面ロジック）
│   ├── Repository層（データアクセス実装）
│   ├── Entity層
│   │   ├── DataModel（ドメインモデル）
│   │   ├── RepositoryInterface（抽象化）
│   │   └── DomainService（ドメインロジック）
│   └── Dependency層（DI設定）
├── [BoundedContext2]Package
│   └── （同様の構成）
└── [BoundedContext3]Package
    └── （同様の構成）
```

## 2. 技術選定

### 2.1 UIフレームワーク
- **SwiftUI** （iOS 15.6以上対応）
- 古いiPhone側でも利用可能なAPIのみ使用

### 2.2 通信実装
- **Bonjour** によるサービス発見（Network.framework）
- **Hummingbird v1.x** （HTTPサーバー実装）
  - v2.xはiOS 17以上のため、v1.xを使用
- **TLS通信** （自己署名証明書）

### 2.3 データ管理
- **SwiftData** （転送元デバイス）
  - 移動履歴の管理
  - 代表的なサムネイル保存
- **UserDefaults** （設定値の保存）

### 2.4 非同期処理
- **Swift Concurrency** （async/await）
- **Actor** によるデータ競合の防止

### 2.5 依存性注入
- **swift-dependencies** ライブラリ

### 2.6 その他のライブラリ
- **PhotoKit** （写真ライブラリアクセス）
- 画像処理は標準APIのみ使用

## 3. パッケージ構成

- 境界づけられたコンテキストの設計は別途検討

## 4. 開発環境
- Xcode 16
- Swift 5.9以上
- iOS Deployment Target: 15.6

## 5. 品質管理
- **swift-format** （コードフォーマット）
- **swift-testing** + **XCTest** （テスト）
- UI Testing（統合テスト）