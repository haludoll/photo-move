import XCTest
@testable import MediaLibraryDomain

final class RectangleDifferenceCalculatorTests: XCTestCase {
    
    // MARK: - calculateDifferences Tests
    
    func testCalculateDifferences_noIntersection() {
        let oldRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let newRect = CGRect(x: 200, y: 200, width: 100, height: 100)
        
        let result = RectangleDifferenceCalculator.calculateDifferences(
            between: oldRect,
            and: newRect
        )
        
        // 交差しない場合：新しい矩形を全て追加、古い矩形を全て削除
        XCTAssertEqual(result.added.count, 1)
        XCTAssertEqual(result.removed.count, 1)
        XCTAssertEqual(result.added[0], newRect)
        XCTAssertEqual(result.removed[0], oldRect)
    }
    
    func testCalculateDifferences_downwardExpansion() {
        // 下方向への拡張
        let oldRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let newRect = CGRect(x: 0, y: 0, width: 100, height: 150)
        
        let result = RectangleDifferenceCalculator.calculateDifferences(
            between: oldRect,
            and: newRect
        )
        
        // 下方向に50pt拡張した部分が追加される
        XCTAssertEqual(result.added.count, 1)
        XCTAssertEqual(result.removed.count, 0)
        
        let expectedAdded = CGRect(x: 0, y: 100, width: 100, height: 50)
        XCTAssertEqual(result.added[0], expectedAdded)
    }
    
    func testCalculateDifferences_upwardExpansion() {
        // 上方向への拡張
        let oldRect = CGRect(x: 0, y: 50, width: 100, height: 100)
        let newRect = CGRect(x: 0, y: 0, width: 100, height: 150)
        
        let result = RectangleDifferenceCalculator.calculateDifferences(
            between: oldRect,
            and: newRect
        )
        
        // 上方向に50pt拡張した部分が追加される
        XCTAssertEqual(result.added.count, 1)
        XCTAssertEqual(result.removed.count, 0)
        
        let expectedAdded = CGRect(x: 0, y: 0, width: 100, height: 50)
        XCTAssertEqual(result.added[0], expectedAdded)
    }
    
    func testCalculateDifferences_downwardContraction() {
        // 下方向への縮小
        let oldRect = CGRect(x: 0, y: 0, width: 100, height: 150)
        let newRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        let result = RectangleDifferenceCalculator.calculateDifferences(
            between: oldRect,
            and: newRect
        )
        
        // 下方向に50pt縮小した部分が削除される
        XCTAssertEqual(result.added.count, 0)
        XCTAssertEqual(result.removed.count, 1)
        
        let expectedRemoved = CGRect(x: 0, y: 100, width: 100, height: 50)
        XCTAssertEqual(result.removed[0], expectedRemoved)
    }
    
    func testCalculateDifferences_upwardContraction() {
        // 上方向への縮小
        let oldRect = CGRect(x: 0, y: 0, width: 100, height: 150)
        let newRect = CGRect(x: 0, y: 50, width: 100, height: 100)
        
        let result = RectangleDifferenceCalculator.calculateDifferences(
            between: oldRect,
            and: newRect
        )
        
        // 上方向に50pt縮小した部分が削除される
        XCTAssertEqual(result.added.count, 0)
        XCTAssertEqual(result.removed.count, 1)
        
        let expectedRemoved = CGRect(x: 0, y: 0, width: 100, height: 50)
        XCTAssertEqual(result.removed[0], expectedRemoved)
    }
    
    func testCalculateDifferences_bothDirectionExpansion() {
        // 上下両方向への拡張
        let oldRect = CGRect(x: 0, y: 100, width: 100, height: 100)
        let newRect = CGRect(x: 0, y: 50, width: 100, height: 200)
        
        let result = RectangleDifferenceCalculator.calculateDifferences(
            between: oldRect,
            and: newRect
        )
        
        // 上下両方に拡張した部分が追加される
        XCTAssertEqual(result.added.count, 2)
        XCTAssertEqual(result.removed.count, 0)
        
        let expectedAddedBottom = CGRect(x: 0, y: 200, width: 100, height: 50)
        let expectedAddedTop = CGRect(x: 0, y: 50, width: 100, height: 50)
        
        XCTAssertTrue(result.added.contains(expectedAddedBottom))
        XCTAssertTrue(result.added.contains(expectedAddedTop))
    }
    
    func testCalculateDifferences_identicalRects() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        let result = RectangleDifferenceCalculator.calculateDifferences(
            between: rect,
            and: rect
        )
        
        // 同じ矩形の場合は追加・削除ともになし
        XCTAssertEqual(result.added.count, 0)
        XCTAssertEqual(result.removed.count, 0)
    }
    
    // MARK: - shouldUpdateCache Tests
    
    func testShouldUpdateCache_significantChange() {
        let currentRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let previousRect = CGRect(x: 0, y: 200, width: 100, height: 100) // 200pt離れている
        let threshold: CGFloat = 50
        
        let shouldUpdate = RectangleDifferenceCalculator.shouldUpdateCache(
            currentRect: currentRect,
            previousRect: previousRect,
            threshold: threshold
        )
        
        // 200pt > 50pt なので更新が必要
        XCTAssertTrue(shouldUpdate)
    }
    
    func testShouldUpdateCache_insignificantChange() {
        let currentRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let previousRect = CGRect(x: 0, y: 30, width: 100, height: 100) // 30pt離れている
        let threshold: CGFloat = 50
        
        let shouldUpdate = RectangleDifferenceCalculator.shouldUpdateCache(
            currentRect: currentRect,
            previousRect: previousRect,
            threshold: threshold
        )
        
        // 30pt < 50pt なので更新不要
        XCTAssertFalse(shouldUpdate)
    }
    
    func testShouldUpdateCache_exactThreshold() {
        let currentRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let previousRect = CGRect(x: 0, y: 100, width: 100, height: 100) // ちょうど100pt離れている
        let threshold: CGFloat = 100
        
        let shouldUpdate = RectangleDifferenceCalculator.shouldUpdateCache(
            currentRect: currentRect,
            previousRect: previousRect,
            threshold: threshold
        )
        
        // 100pt = 100pt なので更新不要（>でチェック）
        XCTAssertFalse(shouldUpdate)
    }
    
    // MARK: - createPreheatRect Tests
    
    func testCreatePreheatRect_defaultExpansion() {
        let visibleRect = CGRect(x: 0, y: 100, width: 200, height: 200)
        
        let preheatRect = RectangleDifferenceCalculator.createPreheatRect(
            from: visibleRect
        )
        
        // デフォルト0.5倍率：上下に100ptずつ拡張
        let expectedRect = CGRect(x: 0, y: 0, width: 200, height: 400)
        XCTAssertEqual(preheatRect, expectedRect)
    }
    
    func testCreatePreheatRect_customExpansion() {
        let visibleRect = CGRect(x: 50, y: 100, width: 100, height: 100)
        
        let preheatRect = RectangleDifferenceCalculator.createPreheatRect(
            from: visibleRect,
            expansionRatio: 1.0
        )
        
        // 1.0倍率：上下に100ptずつ拡張
        let expectedRect = CGRect(x: 50, y: 0, width: 100, height: 300)
        XCTAssertEqual(preheatRect, expectedRect)
    }
    
    func testCreatePreheatRect_zeroExpansion() {
        let visibleRect = CGRect(x: 0, y: 100, width: 200, height: 200)
        
        let preheatRect = RectangleDifferenceCalculator.createPreheatRect(
            from: visibleRect,
            expansionRatio: 0.0
        )
        
        // 0.0倍率：拡張なし
        XCTAssertEqual(preheatRect, visibleRect)
    }
}