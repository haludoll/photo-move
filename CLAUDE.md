# CLAUDE.md

このファイルは、このリポジトリでコードを扱う際にClaude Code (claude.ai/code) にガイダンスを提供します。

## ブランチ戦略

本プロジェクトでは**トランクベース開発戦略**を採用します：

### ブランチフロー
1. **Issue作成**: 機能・バグ修正ごとにGitHub Issueを作成
2. **ブランチ作成**: `issue-{issue番号}-{簡潔な説明}` 形式でブランチを作成
   - 例: `issue-42-add-upload-feature`
3. **初回コミット**: 最初のコミット後、直ちにdraft Pull Requestを作成
4. **継続開発**: ブランチで継続的に開発・コミット
5. **レビュー準備**: 実装完了時にPull Requestを「Ready for review」に変更
6. **自動レビュー**: PR がopenになったタイミングでClaude Codeによる自動レビューを実行
7. **マージ**: レビュー完了後、mainブランチにマージ

### ブランチ命名規則
- `issue-{番号}-{機能名}`: 新機能開発
- `issue-{番号}-fix-{バグ内容}`: バグ修正
- `issue-{番号}-refactor-{対象}`: リファクタリング
- `issue-{番号}-docs-{ドキュメント種類}`: ドキュメント更新

### Pull Request運用
- **Draft作成**: 初回コミット時に自動でdraft PRを作成
- **継続的更新**: 開発中も定期的にコミット・プッシュ
- **マージ条件**: レビュー承認 + CI/CDパス

## コメント記述ガイドライン

### DocCコメント（推奨）
- **対象**: public/internal API、クラス、構造体、プロトコル、重要なメソッド
- **形式**: SwiftDoc形式の三重スラッシュ（`///`）を使用
- **内容**: 目的、パラメータ、戻り値、使用例を記述

### インラインコメント（最小限）
- **原則**: コードを見れば分かることは書かない
- **対象**: 複雑なアルゴリズム、非自明なビジネスロジック、なぜその実装にしたかの理由
- **避けるべき**: 変数代入、関数呼び出し、自明な処理の説明

### 具体例
```swift
// ❌ 悪い例（自明なコメント）
// ユーザー名を取得
let username = user.name

// サーバーを開始
try await server.start()

// ❌ 悪い例（コードの説明）
// ルートエンドポイント
await server.appendRoute(.init(method: .GET, path: "/"), to: handler)

// ✅ 良い例（非自明な理由）
// server.run()は永続的にawaitするため、先にインスタンスを保存
self.server = server

// ✅ 良い例（複雑なロジックの説明）
// 指数バックオフで再試行：初回100ms、最大10秒まで倍々で増加
let delay = min(100 * pow(2, retryCount), 10000)
```

## Swift コード構造ガイドライン

### プロパティの配置順序

**基本原則**: プロパティは機能的に関連するもの同士を近くに配置し、アクセスレベルと性質により整理する

**推奨配置順序**:
1. **Stored Properties** (保存プロパティ)
2. **Computed Properties** (計算プロパティ)  
3. **Initialization** (イニシャライザ)
4. **Instance Methods** (インスタンスメソッド)
5. **Static/Class Members** (静的メンバー)

### MARK活用による構造化

```swift
class ExampleViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var data: [Item] = []
    
    // MARK: - Private Properties  
    private let service: ServiceProtocol
    private let logger = Logger(...)
    
    // MARK: - Computed Properties
    var isDataEmpty: Bool {
        return data.isEmpty
    }
    
    var displayText: String {
        return isLoading ? "読み込み中..." : "完了"
    }
    
    // MARK: - Initialization
    init(service: ServiceProtocol = DefaultService()) {
        self.service = service
    }
    
    // MARK: - Public Methods
    func loadData() async { ... }
    
    // MARK: - Private Methods
    private func processData() { ... }
}
```

### アクセス修飾子の配置
- **public** → **internal** → **private** の順序
- 同じアクセスレベル内では機能グループで整理

## タスク実行時の運用

### 段階的実装の原則
- **Issue調査の必須**: Issue取り組み前にIssueに紐づくコメントを全て確認
- **一度で全てを実装しない**: 一度のタスクですべての実装を行わない
- **段階的指示待ち**: 必要な作業をリストアップ後、上から順に指示を受けて実行
- **レビュー負荷軽減**: 一度のタスクでのコード差分量を最小限に抑制
- **独立動作単位**: 各段階は独立して動作確認可能な単位で実装

### Git運用ルール
- **コミット**: タスク完了時に必ずgit commitとpushを実行
- **コミットメッセージ**: 求められたプロンプトと実施した変更内容を日本語で簡潔に記述
- **Author情報**: コミットメッセージにAuthor情報は含めない
- **小さなコミット単位**: 複雑な機能実装時は、タスクを小さく分割して1つずつコミット
  - レビュー負荷軽減のため、一度にすべてを実装せず段階的に進める
  - 各タスクは独立して動作確認可能な単位で区切る
  - **TODO単位コミット**: 各TODOタスク完了時に必ずコミットを実行
  - 例：「モデル定義」→「API実装」→「UI実装」→「エラーハンドリング」

### コードフォーマット自動実行
- **自動フォーマット**: タスク実行後に必ずコードフォーマットを実行
- **フォーマット対象**: Swiftファイル（.swift）のみ
- **フォーマットコマンド**: `swiftformat`
- **実行タイミング**: コード変更を伴うタスク完了時

#### フォーマット実行手順
1. コード変更を伴うタスクの完了
2. swift-formatによる自動フォーマット実行
3. フォーマット後のコードをgit commitに含める
