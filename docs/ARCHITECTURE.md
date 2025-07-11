# PhotoMove アーキテクチャ設計書

## 1. 概要

PhotoMoveは、ドメイン駆動設計（DDD）に基づいて設計されたiOSアプリケーションです。5つの境界づけられたコンテキストとアプリケーション基盤パッケージに分割され、各パッケージはMVVM + Layered Architectureを採用しています。

## 2. 境界づけられたコンテキスト

### 2.1 MediaLibraryContext
**概要**: 写真・動画の管理、閲覧、検索機能を提供するコンテキスト。ユーザーが写真を見る、選ぶ、整理するためのドメイン。

**主な責務**:
- 写真・動画の一覧表示
- サムネイル管理
- 検索・フィルタリング機能
- メタデータ管理（撮影日時、場所、サイズ等）
- 手元/移行済みの状態管理

**役割別機能**:
- **Primary**: 移行対象の選択、リモート写真の閲覧
- **Storage**: 受信した写真の管理、一覧表示

**主要な概念**:
- Media: 写真・動画エンティティ
- MediaMetadata: メタデータ
- MediaLocation: 保存場所（ローカル/リモート）
- MediaFilter: 検索・フィルター条件

### 2.2 NetworkConnectionContext  
**概要**: 低レベルのネットワーク通信基盤を提供する技術的なコンテキスト。UIを持たない純粋なインフラストラクチャ層。デバイス発見から通信確立まで担当。

**主な責務**:
- Bonjourによるサービス発見・広告
- デバイスのIPアドレス解決
- HTTPSサーバーの起動・停止
- TLS暗号化通信の確立
- HTTPエンドポイントの管理
- 接続状態の管理

**役割別機能**:
- 役割に依存しない共通インフラ

**主要な概念**:
- HTTPServer: HTTPSサーバー管理
- BonjourService: サービス発見・デバイス検出
- DeviceEndpoint: 発見されたデバイスの接続情報
- TLSConfiguration: セキュア通信設定
- HTTPEndpoint: エンドポイント定義

### 2.3 SystemMonitoringContext
**概要**: 自分自身のシステムリソース状態を監視するコンテキスト。特にストレージ容量の監視が主要機能。

**主な責務**:
- ストレージ容量の監視
- 閾値チェックとアラート
- システムリソース情報の提供
- 容量不足の検出

**役割別機能**:
- **Primary**: 容量不足の検出・通知
- **Storage**: 受信可能容量の監視

**主要な概念**:
- StorageInfo: ストレージ情報
- SystemResource: リソース状態
- MonitoringThreshold: 監視閾値
- CapacityAlert: 容量アラート

### 2.4 AssetTransferContext
**概要**: アセット（写真・動画）の転送機能を提供するコンテキスト。送信・受信のAPIとビジネスロジックを実装。

**主な責務**:
- 転送APIの実装（送信/受信）
- 転送進捗の管理
- エラーハンドリング
- 転送完了後の処理

**役割別機能**:
- **Primary**: アセット送信API利用
- **Storage**: アセット受信API実装

**主要な概念**:
- TransferRequest: 転送リクエスト
- TransferProgress: 進捗状態
- TransferResult: 転送結果
- AssetPackage: 転送データパッケージ

**API定義**:
```
GET  /assets/:id        - アセットデータの取得
POST /transfer/receive  - アセットの受信
```

### 2.5 DeviceRoleContext
**概要**: PhotoMoveアプリにおけるデバイスの役割（Primary/Storage）を管理するコンテキスト。アプリ全体の動作モードを決定する。

**主な責務**:
- デバイス役割の決定・保存
- 役割の永続化
- 役割切り替え機能
- 役割に基づく機能の有効化

**役割別機能**:
- 役割に依存しない（役割を決定する側）

**主要な概念**:
- DeviceRole: Primary/Storage
- RoleConfiguration: 役割設定
- RoleTransition: 役割切り替え

## 3. アプリケーション基盤パッケージ

### 3.1 AppFoundation
**概要**: アプリケーション全体の基盤となるパッケージ。各コンテキストの統合、初期化、設定管理を担当。

**主な責務**:
- アプリケーションの初期化・オンボーディング
- アプリ設定の管理
- 各コンテキストの統合・組み立て
- ナビゲーション管理

**主要な概念**:
- AppConfig: アプリケーション設定
- OnboardingState: オンボーディング状態
- AppCoordinator: アプリ全体の協調制御

## 4. レイヤー構成

各パッケージは以下のレイヤー構成を持ちます：

```
[Package]/
├── Presentation/     # View (SwiftUI)
├── ViewModel/        # 画面ロジック
├── Repository/       # データアクセス実装
├── Entity/          
│   ├── DataModel/    # ドメインモデル
│   ├── RepositoryInterface/ # 抽象化
│   └── DomainService/ # ドメインロジック
└── Dependency/       # DI設定
```

## 5. パッケージ構成

**最終的な6つのパッケージ：**
1. **MediaLibraryContext** - 写真・動画の管理
2. **NetworkConnectionContext** - 通信基盤とデバイス発見  
3. **SystemMonitoringContext** - システム状態監視
4. **AssetTransferContext** - アセット転送
5. **DeviceRoleContext** - デバイス役割管理
6. **AppFoundation** - アプリケーション基盤

## 6. 依存関係

```
AppFoundation ──→ DeviceRoleContext
    │        └→ MediaLibraryContext ──→ AssetTransferContext ──→ NetworkConnectionContext
    │                                  
    └──────────→ SystemMonitoringContext
```

### 6.1 依存関係の詳細

1. **NetworkConnectionContext**: 最下位層、他に依存しない（通信基盤とデバイス発見）
2. **AssetTransferContext**: NetworkConnectionを利用してAPI実装
3. **MediaLibraryContext**: AssetTransferを利用して写真を送信・取得
4. **SystemMonitoringContext**: 完全に独立
5. **DeviceRoleContext**: 完全に独立
6. **AppFoundation**: 各コンテキストを統合（最上位層）

### 6.2 アプリケーション統合

各コンテキストはそれぞれ独立した機能を提供し、AppFoundationで以下のように統合されます：

1. AppFoundationがDeviceRoleContextでデバイスの役割を決定
2. 役割に応じて各コンテキストの適切なViewを選択・表示
3. 各コンテキストは役割に関わらず全機能を公開（AppFoundationが選択）

### 6.3 役割別インターフェース

各コンテキストは役割（Primary/Storage）に応じた異なるインターフェースを提供しますが、コンテキスト自体は統一されています：

- **Primary役割**: 容量確保、写真選択、送信、リモート閲覧
- **Storage役割**: 受信、保存、提供、容量管理

Presentation層で役割に応じたViewとViewModelを使い分けることで、適切な機能を利用します。

## 7. データフロー

### 7.1 写真の移行フロー
1. SystemMonitoringが容量不足を検出
2. MediaLibraryで移行対象を選択
3. NetworkConnectionでデバイスを発見・接続
4. AssetTransferがNetworkConnectionを使用して転送実行
5. 完了後、MediaLibraryのメタデータを更新

### 7.2 写真の閲覧フロー
1. MediaLibraryで写真一覧を表示
2. 移行済み写真の選択時、NetworkConnectionで接続確認
3. AssetTransferを通じて写真データを取得
4. MediaLibraryで表示

## 8. 技術的な考慮事項

### 8.1 非同期処理
- Swift Concurrencyを全面的に採用
- Actorによるデータ競合の防止

### 8.2 エラーハンドリング
- 各コンテキストで適切なエラー型を定義
- ネットワークエラーは自動リトライ機能を実装

### 8.3 パフォーマンス
- 大量の写真に対応するためのページング
- サムネイルの効率的なキャッシング

## 9. セキュリティ

### 9.1 通信セキュリティ
- TLS 1.3による暗号化通信
- 自己署名証明書の適切な管理

### 9.2 データ保護
- 写真データは端末外に送信しない（ローカルネットワークのみ）
- アプリサンドボックスによる保護

## 10. 拡張性

### 10.1 新機能の追加
- 新しいコンテキストの追加が容易
- 既存コンテキストへの影響を最小限に

### 10.2 将来の拡張例
- PhotoOrganizationContext: 写真の整理・重複検出
- BackupContext: 自動バックアップ機能
- CloudSyncContext: クラウド連携（オプション）