# PhotoMove 推奨開発コマンド

## 日常的な開発コマンド

### コードフォーマット
```bash
# プロジェクト全体のSwiftコードをフォーマット
./Scripts/format.sh

# 手動でswift-formatを実行
swift-format --configuration .swift-format --in-place [ファイル名]
```

### ビルド
```bash
# フォーマット→ビルドを一括実行
./Scripts/build.sh

# MediaLibraryパッケージのみビルド
swift build --package-path MediaLibrary

# AppFoundationパッケージのみビルド  
swift build --package-path AppFoundation

# iOSシミュレータ向けXcodeビルド（動作確認用）
xcodebuild -workspace photo-move.xcworkspace -scheme photo-move -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### テスト
```bash
# フォーマット→テストを一括実行
./Scripts/test.sh

# MediaLibraryパッケージのみテスト
swift test --package-path MediaLibrary

# AppFoundationパッケージのみテスト
swift test --package-path AppFoundation
```

## Git関連コマンド（Darwinシステム）

### 基本的なGitコマンド
```bash
# 基本操作
git status
git add .
git commit -m "コミットメッセージ"
git push

# ブランチ操作
git checkout -b issue-番号-機能名
git branch
git merge main
```

## システムユーティリティ（Darwin）

### ファイル・ディレクトリ操作
```bash
# リスト表示
ls -la
find . -name "*.swift"

# ファイル検索・内容確認
grep -r "検索文字列" .
cat ファイル名
head -n 10 ファイル名
tail -f ログファイル
```

### プロセス・システム情報
```bash
# プロセス確認
ps aux | grep xcode
top

# ディスク使用量
df -h
du -sh *
```

## 必須セットアップコマンド

### 依存関係インストール
```bash
# swift-formatのインストール（Homebrew）
brew install swift-format

# Xcodeコマンドラインツール
xcode-select --install
```

## トラブルシューティング

### パッケージ依存関係のリセット
```bash
# Package.resolvedファイルを削除してクリーンビルド
rm MediaLibrary/Package.resolved
rm AppFoundation/Package.resolved
swift package --package-path MediaLibrary reset
swift package --package-path AppFoundation reset
```

### Xcodeキャッシュクリア
```bash
# Derived Dataのクリア
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## 開発フロー推奨コマンド順序

1. **作業開始時**:
   ```bash
   git status
   git pull origin main
   ```

2. **コード変更後**:
   ```bash
   ./Scripts/format.sh
   ./Scripts/test.sh
   ./Scripts/build.sh
   ```

3. **コミット時**:
   ```bash
   git add .
   git commit -m "実装内容の説明"
   git push
   ```