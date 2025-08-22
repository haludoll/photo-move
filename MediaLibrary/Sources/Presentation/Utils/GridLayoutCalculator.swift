import CoreGraphics

/// グリッドレイアウトの計算を行うユーティリティ
public enum GridLayoutCalculator {
    /// グリッドアイテムのサイズを計算
    /// - Parameters:
    ///   - containerWidth: コンテナの幅
    ///   - columns: 列数
    ///   - spacing: アイテム間のスペース
    /// - Returns: 計算されたアイテムサイズ
    public static func calculateItemSize(
        containerWidth: CGFloat,
        columns: CGFloat,
        spacing: CGFloat
    ) -> CGSize {
        let totalSpacing = spacing * (columns - 1)
        let itemWidth = (containerWidth - totalSpacing) / columns
        return CGSize(width: itemWidth, height: itemWidth)
    }

    /// サムネイル用のサイズを計算（高解像度対応）
    /// - Parameters:
    ///   - itemSize: セルのサイズ
    ///   - scale: スクリーン倍率
    ///   - qualityMultiplier: 品質倍率（通常3.0で高解像度）
    /// - Returns: サムネイルサイズ
    public static func calculateThumbnailSize(
        itemSize: CGSize,
        scale: CGFloat,
        qualityMultiplier: CGFloat = 3.0
    ) -> CGSize {
        let targetSize = itemSize.width * qualityMultiplier * scale
        return CGSize(width: targetSize, height: targetSize)
    }
}
