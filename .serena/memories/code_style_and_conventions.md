# PhotoMove コードスタイル・規約

## コードフォーマット設定（.swift-format）
- **行の長さ**: 120文字
- **インデント**: スペース4つ
- **タブ幅**: 4
- **最大空行**: 1行
- **アクセスレベル**: ファイルスコープの宣言はprivateがデフォルト

## コメント記述ガイドライン

### DocCコメント（推奨）
- **対象**: public/internal API、クラス、構造体、プロトコル、重要なメソッド
- **形式**: SwiftDoc形式の三重スラッシュ（`///`）を使用
- **内容**: 目的、パラメータ、戻り値、使用例を記述

### インラインコメント（最小限）
- **原則**: コードを見れば分かることは書かない
- **対象**: 複雑なアルゴリズム、非自明なビジネスロジック、なぜその実装にしたかの理由
- **避けるべき**: 変数代入、関数呼び出し、自明な処理の説明

## Swift コード構造ガイドライン

### プロパティの配置順序
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
    
    // MARK: - Computed Properties
    var isDataEmpty: Bool { data.isEmpty }
    
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

## 命名規約（実際のコードから確認）
- **パッケージアクセス**: `package` キーワードを活用
- **型名**: PascalCase（例: `MediaLibraryView`, `Media`）
- **プロパティ・メソッド**: camelCase
- **値オブジェクト**: ネストした構造体を活用（例: `Media.ID`, `Media.Metadata`）
- **エラー型**: `MediaError` のように型名 + Error

## DDD設計パターン
- **エンティティ**: `Identifiable`, `Hashable` に準拠
- **値オブジェクト**: ネストした構造体として実装
- **ドメインエラー**: 各コンテキストで専用エラー型を定義
- **バリデーション**: イニシャライザで入力値検証を実施