# PhotoMove 技術スタック

## アーキテクチャ
- **ドメイン駆動設計（DDD）** を全体に適用
- 境界づけられたコンテキストごとにSwift Packageを分割
- 各コンテキスト内で **MVVM + Layered Architecture** を採用

## Swift & iOS関連
- **Swift 6.1** (swift-tools-version: 6.1)
- **iOS 15.6以上** をサポート
- **SwiftUI** でUI実装
- **Swift Concurrency** (async/await) で非同期処理
- **Actor** によるデータ競合の防止

## 主要フレームワーク・ライブラリ
- **PhotoKit**: 写真ライブラリアクセス
- **Network.framework**: Bonjourによるサービス発見
- **Hummingbird v1.x**: HTTPサーバー実装（v2.xはiOS 17以上のため）
- **SwiftData**: 転送元デバイスでの移動履歴・サムネイル保存
- **UserDefaults**: 設定値の保存
- **swift-format**: コードフォーマット（Apple公式）
- **swift-dependencies**: 依存性注入
- **swift-testing + XCTest**: テスト

## セキュリティ
- **TLS 1.3** による暗号化通信
- **自己署名証明書**
- 100%ローカルネットワーク処理（データは外部送信しない）

## 開発環境
- **Xcode 16**
- **macOS Darwin**
- **iOS Deployment Target**: 15.6

## パッケージ構成（DDD境界づけられたコンテキスト）
1. **MediaLibraryContext** - 写真・動画の管理
2. **NetworkConnectionContext** - 通信基盤とデバイス発見
3. **SystemMonitoringContext** - システム状態監視
4. **AssetTransferContext** - アセット転送と転送時役割管理
5. **AppFoundation** - アプリケーション基盤

## レイヤー構成（各パッケージ内）
```
[Package]/
├── Presentation/          # SwiftUI Views & ViewModels
├── Application/          # アプリケーションサービス
├── Domain/               # エンティティ、値オブジェクト、集約
├── Infrastructure/       # リポジトリ実装、外部API
└── DependencyInjection/  # DI設定
```