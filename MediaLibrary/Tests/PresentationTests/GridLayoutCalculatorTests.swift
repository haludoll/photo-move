@testable import MediaLibraryPresentation
import XCTest

final class GridLayoutCalculatorTests: XCTestCase {
    // MARK: - calculateItemSize Tests

    func testCalculateItemSize_standardCase() {
        // 320pt幅、4列、2ptスペースの場合
        let itemSize = GridLayoutCalculator.calculateItemSize(
            containerWidth: 320,
            columns: 4,
            spacing: 2
        )

        // 期待値: (320 - 6) / 4 = 78.5
        XCTAssertEqual(itemSize.width, 78.5, accuracy: 0.001)
        XCTAssertEqual(itemSize.height, 78.5, accuracy: 0.001)
    }

    func testCalculateItemSize_iPhoneSEWidth() {
        // iPhone SE (375pt)の場合
        let itemSize = GridLayoutCalculator.calculateItemSize(
            containerWidth: 375,
            columns: 4,
            spacing: 2
        )

        // 期待値: (375 - 6) / 4 = 92.25
        XCTAssertEqual(itemSize.width, 92.25, accuracy: 0.001)
        XCTAssertEqual(itemSize.height, 92.25, accuracy: 0.001)
    }

    func testCalculateItemSize_iPadWidth() {
        // iPadの幅でより多い列数の場合
        let itemSize = GridLayoutCalculator.calculateItemSize(
            containerWidth: 768,
            columns: 6,
            spacing: 2
        )

        // 期待値: (768 - 10) / 6 = 126.33...
        XCTAssertEqual(itemSize.width, 126.33333333333333, accuracy: 0.001)
        XCTAssertEqual(itemSize.height, 126.33333333333333, accuracy: 0.001)
    }

    func testCalculateItemSize_zeroSpacing() {
        // スペースが0の場合
        let itemSize = GridLayoutCalculator.calculateItemSize(
            containerWidth: 320,
            columns: 4,
            spacing: 0
        )

        // 期待値: 320 / 4 = 80
        XCTAssertEqual(itemSize.width, 80, accuracy: 0.001)
        XCTAssertEqual(itemSize.height, 80, accuracy: 0.001)
    }

    func testCalculateItemSize_singleColumn() {
        // 1列の場合
        let itemSize = GridLayoutCalculator.calculateItemSize(
            containerWidth: 320,
            columns: 1,
            spacing: 2
        )

        // 期待値: (320 - 0) / 1 = 320
        XCTAssertEqual(itemSize.width, 320, accuracy: 0.001)
        XCTAssertEqual(itemSize.height, 320, accuracy: 0.001)
    }

    // MARK: - calculateThumbnailSize Tests

    func testCalculateThumbnailSize_standard() {
        let itemSize = CGSize(width: 80, height: 80)
        let thumbnailSize = GridLayoutCalculator.calculateThumbnailSize(
            itemSize: itemSize,
            scale: 3.0, // iPhone Pro Max scale
            qualityMultiplier: 2.0
        )

        // 期待値: 80 * 2.0 * 3.0 = 480
        XCTAssertEqual(thumbnailSize.width, 480, accuracy: 0.001)
        XCTAssertEqual(thumbnailSize.height, 480, accuracy: 0.001)
    }

    func testCalculateThumbnailSize_lowDensityScreen() {
        let itemSize = CGSize(width: 100, height: 100)
        let thumbnailSize = GridLayoutCalculator.calculateThumbnailSize(
            itemSize: itemSize,
            scale: 1.0, // 非Retina
            qualityMultiplier: 2.0
        )

        // 期待値: 100 * 2.0 * 1.0 = 200
        XCTAssertEqual(thumbnailSize.width, 200, accuracy: 0.001)
        XCTAssertEqual(thumbnailSize.height, 200, accuracy: 0.001)
    }

    func testCalculateThumbnailSize_customQualityMultiplier() {
        let itemSize = CGSize(width: 50, height: 50)
        let thumbnailSize = GridLayoutCalculator.calculateThumbnailSize(
            itemSize: itemSize,
            scale: 2.0,
            qualityMultiplier: 1.5
        )

        // 期待値: 50 * 1.5 * 2.0 = 150
        XCTAssertEqual(thumbnailSize.width, 150, accuracy: 0.001)
        XCTAssertEqual(thumbnailSize.height, 150, accuracy: 0.001)
    }

    func testCalculateThumbnailSize_defaultQualityMultiplier() {
        let itemSize = CGSize(width: 60, height: 60)
        let thumbnailSize = GridLayoutCalculator.calculateThumbnailSize(
            itemSize: itemSize,
            scale: 2.0
        )

        // デフォルト倍率3.0での期待値: 60 * 3.0 * 2.0 = 360
        XCTAssertEqual(thumbnailSize.width, 360, accuracy: 0.001)
        XCTAssertEqual(thumbnailSize.height, 360, accuracy: 0.001)
    }
}
