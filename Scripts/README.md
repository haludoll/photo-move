# Scripts

このディレクトリには、プロジェクト全体で使用するスクリプトが含まれています。

## 利用可能なスクリプト

### format.sh
プロジェクト全体のSwiftコードをフォーマットします（Apple公式のswift-formatを使用）。

```bash
./Scripts/format.sh
```

### build.sh
コードをフォーマットしてからプロジェクトをビルドします。

```bash
./Scripts/build.sh
```

### test.sh
コードをフォーマットしてからテストを実行します。

```bash
./Scripts/test.sh
```

### xcode-swiftformat.sh
XcodeのBuild Phaseから呼び出される自動フォーマットスクリプトです（Apple公式のswift-formatを使用）。
直接実行する必要はありません。

## Xcode統合

### SwiftFormat自動実行の設定方法

1. Xcodeでプロジェクトを開く
2. プロジェクトナビゲータでプロジェクトを選択
3. ターゲットを選択
4. "Build Phases"タブを選択
5. "+"ボタンをクリックし、"New Run Script Phase"を選択
6. 以下のスクリプトを追加：

```bash
if [ -f "${SRCROOT}/../Scripts/xcode-swiftformat.sh" ]; then
    "${SRCROOT}/../Scripts/xcode-swiftformat.sh"
fi
```

7. "Input Files"に以下を追加（オプション）：
   - `$(SRCROOT)/$(PROJECT_NAME)`
   
8. "Based on dependency analysis"のチェックを外す（推奨）

これにより、ビルド時に自動的にSwiftFormatが実行されます。

## 設定ファイル

swift-formatの設定は、プロジェクトルートの`.swift-format`ファイルで管理されています。