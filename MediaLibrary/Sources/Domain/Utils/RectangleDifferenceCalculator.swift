import CoreGraphics

/// 矩形の差分計算を行うユーティリティ
public enum RectangleDifferenceCalculator {
    /// 矩形差分の結果
    public struct DifferenceResult {
        public let added: [CGRect]
        public let removed: [CGRect]

        public init(added: [CGRect], removed: [CGRect]) {
            self.added = added
            self.removed = removed
        }
    }

    /// 2つの矩形の差分を計算し、追加・削除すべき範囲を返す
    /// - Parameters:
    ///   - old: 古い矩形
    ///   - new: 新しい矩形
    /// - Returns: 追加・削除すべき矩形の配列
    public static func calculateDifferences(
        between old: CGRect,
        and new: CGRect
    ) -> DifferenceResult {
        if old.intersects(new) {
            var added = [CGRect]()
            var removed = [CGRect]()

            // 下方向に拡張した部分
            if new.maxY > old.maxY {
                added.append(CGRect(
                    x: new.origin.x,
                    y: old.maxY,
                    width: new.width,
                    height: new.maxY - old.maxY
                ))
            }

            // 上方向に拡張した部分
            if old.minY > new.minY {
                added.append(CGRect(
                    x: new.origin.x,
                    y: new.minY,
                    width: new.width,
                    height: old.minY - new.minY
                ))
            }

            // 下方向に縮小した部分
            if new.maxY < old.maxY {
                removed.append(CGRect(
                    x: old.origin.x,
                    y: new.maxY,
                    width: old.width,
                    height: old.maxY - new.maxY
                ))
            }

            // 上方向に縮小した部分
            if old.minY < new.minY {
                removed.append(CGRect(
                    x: old.origin.x,
                    y: old.minY,
                    width: old.width,
                    height: new.minY - old.minY
                ))
            }

            return DifferenceResult(added: added, removed: removed)
        } else {
            // 交差しない場合：新しい範囲を全て追加、古い範囲を全て削除
            return DifferenceResult(added: [new], removed: [old])
        }
    }

    /// キャッシュ更新が必要かどうかを判定
    /// - Parameters:
    ///   - currentRect: 現在の矩形
    ///   - previousRect: 前回の矩形
    ///   - threshold: しきい値（通常は画面高さの1/3）
    /// - Returns: 更新が必要かどうか
    public static func shouldUpdateCache(
        currentRect: CGRect,
        previousRect: CGRect,
        threshold: CGFloat
    ) -> Bool {
        let delta = abs(currentRect.midY - previousRect.midY)
        return delta > threshold
    }

    /// プリロード用の矩形を作成
    /// - Parameters:
    ///   - visibleRect: 表示中の矩形
    ///   - expansionRatio: 拡張倍率（0.5で上下50%ずつ拡張）
    /// - Returns: プリロード用矩形
    public static func createPreheatRect(
        from visibleRect: CGRect,
        expansionRatio: CGFloat = 0.5
    ) -> CGRect {
        return visibleRect.insetBy(dx: 0, dy: -expansionRatio * visibleRect.height)
    }
}
