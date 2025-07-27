//
//  MediaLibraryUITests.swift
//  media-library-demoUITests
//
//  Created by Claude on 2025/07/27.
//

import XCTest

final class MediaLibraryUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        
        // 写真ライブラリへのアクセス許可を自動的に許可
        addUIInterruptionMonitor(withDescription: "写真ライブラリへのアクセス許可") { alert in
            let allowButton = alert.buttons["すべての写真へのアクセスを許可"]
            if allowButton.exists {
                allowButton.tap()
                return true
            }
            
            // 英語環境の場合
            let allowButtonEN = alert.buttons["Allow Access to All Photos"]
            if allowButtonEN.exists {
                allowButtonEN.tap()
                return true
            }
            
            return false
        }
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - 基本的な表示テスト
    
    @MainActor
    func testPhotoGridDisplay() throws {
        // アプリを起動
        app.launch()
        
        // NavigationViewが表示されることを確認
        let navigationView = app.navigationBars.firstMatch
        XCTAssertTrue(navigationView.waitForExistence(timeout: 5))
        
        // グリッドが表示されることを確認（ScrollViewの存在で判定）
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 10))
    }
    
    // MARK: - ローディング状態のテスト
    
    @MainActor
    func testLoadingIndicator() throws {
        app.launch()
        
        // 初回起動時のローディングインジケーターを確認
        let progressView = app.progressIndicators.firstMatch
        
        // ローディングインジケーターが表示される可能性がある
        // （写真の枚数や読み込み速度によっては表示されない場合もある）
        if progressView.exists {
            // ローディングが完了して消えることを確認
            XCTAssertTrue(progressView.waitForNonExistence(timeout: 30))
        }
    }
    
    // MARK: - 空状態のテスト
    
    @MainActor
    func testEmptyState() throws {
        // 注意: このテストは実際のデバイスに写真がない場合のみ成功します
        app.launch()
        
        // 空状態のテキストを探す
        let emptyStateText = app.staticTexts["写真がありません"]
        
        // 写真がある場合はこのテストはスキップ
        if emptyStateText.waitForExistence(timeout: 5) {
            XCTAssertTrue(emptyStateText.exists)
            
            // 空状態のアイコンも表示されているはず
            let images = app.images
            XCTAssertTrue(images.count > 0)
        }
    }
    
    // MARK: - サムネイル表示のテスト
    
    @MainActor
    func testThumbnailDisplay() throws {
        app.launch()
        
        // グリッドが表示されるまで待機
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 10))
        
        // 写真がある場合、画像要素が存在することを確認
        let images = app.images
        
        // 少なくとも1つ以上の画像が表示されるまで待機
        let firstImage = images.firstMatch
        if firstImage.waitForExistence(timeout: 15) {
            XCTAssertTrue(images.count > 0)
            
            // サムネイルのサイズが適切か確認（正方形であること）
            let frame = firstImage.frame
            let tolerance: CGFloat = 5.0 // 許容誤差
            XCTAssertEqual(frame.width, frame.height, accuracy: tolerance)
        }
    }
    
    // MARK: - スクロールのテスト
    
    @MainActor
    func testScrolling() throws {
        app.launch()
        
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 10))
        
        // 写真が複数ある場合のみスクロールをテスト
        let images = app.images
        if images.count > 10 {
            // 下にスクロール
            scrollView.swipeUp()
            
            // スクロール後も画像が表示されていることを確認
            XCTAssertTrue(images.count > 0)
            
            // 上にスクロール（元に戻る）
            scrollView.swipeDown()
        }
    }
    
    // MARK: - エラーハンドリングのテスト
    
    @MainActor
    func testPermissionDeniedAlert() throws {
        // 注意: このテストは権限が拒否されている状態でのみ成功します
        // 実際のテスト環境では、権限をリセットするか、
        // 別のテストターゲットで権限拒否状態をシミュレートする必要があります
        
        app.launch()
        
        // エラーアラートを探す
        let alert = app.alerts["エラー"]
        
        if alert.waitForExistence(timeout: 5) {
            // 権限拒否メッセージが表示されているか確認
            let messageText = alert.staticTexts.element(boundBy: 1).label
            XCTAssertTrue(messageText.contains("写真ライブラリへのアクセスが拒否されています"))
            
            // OKボタンをタップしてアラートを閉じる
            alert.buttons["OK"].tap()
            XCTAssertFalse(alert.exists)
        }
    }
    
    // MARK: - パフォーマンステスト
    
    @MainActor
    func testScrollPerformance() throws {
        app.launch()
        
        let scrollView = app.scrollViews.firstMatch
        guard scrollView.waitForExistence(timeout: 10) else {
            XCTSkip("ScrollViewが見つかりません")
            return
        }
        
        // スクロールパフォーマンスを測定
        measure(metrics: [XCTOSSignpostMetric.scrollingInView]) {
            scrollView.swipeUp()
            scrollView.swipeDown()
        }
    }
}