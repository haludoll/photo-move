# MediaLibraryPresentation

写真ライブラリ機能のプレゼンテーション層を提供するパッケージです。

## 概要

このパッケージは、MediaLibraryドメインのUI表示に関する以下の責務を担います：

- ViewModels（MVVMパターン）
- SwiftUIビュー
- UI状態管理
- ユーザーインタラクション処理

## アーキテクチャ

### MVVM Pattern
- **View**: SwiftUIビューによるUI表示
- **ViewModel**: ビジネスロジックとUI状態の管理
- **Model**: MediaLibraryドメインのエンティティとサービス

## 依存関係

- `MediaLibraryDomain`: ドメインモデルとビジネスルール
- `MediaLibraryApplication`: アプリケーションサービス
- `AppFoundation`: 共通UI/ユーティリティ

## 使用方法

```swift
import MediaLibraryPresentation

struct ContentView: View {
    @StateObject private var viewModel = PhotoLibraryViewModel()
    
    var body: some View {
        PhotoLibraryView(viewModel: viewModel)
    }
}
```