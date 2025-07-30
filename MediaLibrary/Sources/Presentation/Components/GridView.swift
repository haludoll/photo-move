import SwiftUI
import UIKit

/// 汎用的なグリッドビュー
/// UICollectionViewをSwiftUIで使用するためのラッパー
struct GridView<Item: Identifiable, Content: View>: UIViewRepresentable {
    // MARK: - Properties
    
    /// 表示するアイテム
    let items: [Item]
    
    /// グリッドの列数
    let columns: Int
    
    /// セル間のスペーシング
    let spacing: CGFloat
    
    /// 選択されているアイテムのID（nilの場合は選択不可）
    @Binding var selectedIDs: Set<Item.ID>?
    
    /// 各アイテムのコンテンツを生成するクロージャ
    let content: (Item, Bool) -> Content
    
    /// アイテムが表示された時のコールバック
    let onItemAppear: ((Item) -> Void)?
    
    /// アイテムがタップされた時のコールバック
    let onItemTap: ((Item) -> Void)?
    
    // MARK: - Initialization
    
    init(
        items: [Item],
        columns: Int,
        spacing: CGFloat = 2,
        selectedIDs: Binding<Set<Item.ID>?>,
        @ViewBuilder content: @escaping (Item, Bool) -> Content,
        onItemAppear: ((Item) -> Void)? = nil,
        onItemTap: ((Item) -> Void)? = nil
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self._selectedIDs = selectedIDs
        self.content = content
        self.onItemAppear = onItemAppear
        self.onItemTap = onItemTap
    }
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        
        let collectionView = SelectableCollectionView<Item>(frame: .zero, collectionViewLayout: layout)
        collectionView.columns = columns
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator
        
        // セルの登録
        collectionView.register(
            HostingCollectionViewCell<Content>.self,
            forCellWithReuseIdentifier: "Cell"
        )
        
        context.coordinator.setupGestureRecognizers(for: collectionView)
        
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        guard let collectionView = uiView as? SelectableCollectionView<Item> else { return }
        
        context.coordinator.items = items
        context.coordinator.selectedIDs = selectedIDs
        collectionView.columns = columns
        
        // データの更新
        collectionView.reloadData()
        
        // レイアウトの更新
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = spacing
            layout.minimumLineSpacing = spacing
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            items: items,
            selectedIDs: selectedIDs,
            content: content,
            onItemAppear: onItemAppear,
            onItemTap: onItemTap,
            selectedIDsBinding: $selectedIDs
        )
    }
}

// MARK: - Coordinator

extension GridView {
    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
        var items: [Item]
        var selectedIDs: Set<Item.ID>?
        let content: (Item, Bool) -> Content
        let onItemAppear: ((Item) -> Void)?
        let onItemTap: ((Item) -> Void)?
        let selectedIDsBinding: Binding<Set<Item.ID>?>
        
        private var panGestureRecognizer: UIPanGestureRecognizer?
        private var autoScrollTimer: CADisplayLink?
        private var initialSelectionState: Bool = false
        private var lastSelectedIndexPath: IndexPath?
        
        init(
            items: [Item],
            selectedIDs: Set<Item.ID>?,
            content: @escaping (Item, Bool) -> Content,
            onItemAppear: ((Item) -> Void)?,
            onItemTap: ((Item) -> Void)?,
            selectedIDsBinding: Binding<Set<Item.ID>?>
        ) {
            self.items = items
            self.selectedIDs = selectedIDs
            self.content = content
            self.onItemAppear = onItemAppear
            self.onItemTap = onItemTap
            self.selectedIDsBinding = selectedIDsBinding
        }
        
        // MARK: - Gesture Setup
        
        func setupGestureRecognizers(for collectionView: UICollectionView) {
            // タップジェスチャー（既存のdidSelectItemAtで処理）
            
            // パンジェスチャー（スワイプ選択用）
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            panGesture.delegate = self
            collectionView.addGestureRecognizer(panGesture)
            self.panGestureRecognizer = panGesture
        }
        
        // MARK: - UICollectionViewDataSource
        
        public func numberOfSections(in collectionView: UICollectionView) -> Int {
            return 1
        }
        
        public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return items.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! HostingCollectionViewCell<Content>
            
            let item = items[indexPath.item]
            let isSelected = selectedIDs?.contains(item.id) ?? false
            let contentView = content(item, isSelected)
            
            cell.configure(with: contentView)
            
            return cell
        }
        
        // MARK: - UICollectionViewDelegate
        
        func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
            let item = items[indexPath.item]
            onItemAppear?(item)
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            // 選択モードでない場合はタップコールバックのみ
            guard selectedIDs != nil else {
                let item = items[indexPath.item]
                onItemTap?(item)
                return
            }
            
            toggleSelection(at: indexPath, in: collectionView)
        }
        
        // MARK: - UICollectionViewDelegateFlowLayout
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
                return CGSize(width: 100, height: 100)
            }
            
            let columns = CGFloat((collectionView as? SelectableCollectionView<Item>)?.columns ?? 3)
            let width = collectionView.bounds.width
            let totalSpacing = layout.minimumInteritemSpacing * (columns - 1)
            let itemWidth = (width - totalSpacing) / columns
            
            return CGSize(width: itemWidth, height: itemWidth)
        }
        
        // MARK: - Selection Handling
        
        private func toggleSelection(at indexPath: IndexPath, in collectionView: UICollectionView) {
            let item = items[indexPath.item]
            
            if selectedIDs?.contains(item.id) == true {
                selectedIDs?.remove(item.id)
            } else {
                if selectedIDs == nil {
                    selectedIDs = Set<Item.ID>()
                }
                selectedIDs?.insert(item.id)
            }
            
            selectedIDsBinding.wrappedValue = selectedIDs
            collectionView.reloadItems(at: [indexPath])
            
            // ハプティックフィードバック
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        
        // MARK: - Pan Gesture Handling
        
        @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
            guard let collectionView = gesture.view as? UICollectionView,
                  selectedIDs != nil else { return }
            
            let location = gesture.location(in: collectionView)
            
            switch gesture.state {
            case .began:
                handlePanBegan(at: location, in: collectionView)
            case .changed:
                handlePanChanged(at: location, in: collectionView)
            case .ended, .cancelled:
                handlePanEnded()
            default:
                break
            }
        }
        
        private func handlePanBegan(at location: CGPoint, in collectionView: UICollectionView) {
            guard let indexPath = collectionView.indexPathForItem(at: location) else { return }
            
            let item = items[indexPath.item]
            initialSelectionState = !(selectedIDs?.contains(item.id) ?? false)
            lastSelectedIndexPath = indexPath
            
            // 最初のアイテムの選択状態を切り替え
            toggleSelection(at: indexPath, in: collectionView)
            
            // 自動スクロールの開始
            startAutoScrollIfNeeded(in: collectionView)
        }
        
        private func handlePanChanged(at location: CGPoint, in collectionView: UICollectionView) {
            guard let indexPath = collectionView.indexPathForItem(at: location),
                  indexPath != lastSelectedIndexPath else { return }
            
            let item = items[indexPath.item]
            let isCurrentlySelected = selectedIDs?.contains(item.id) ?? false
            
            // 初期状態と異なる場合のみ切り替え
            if isCurrentlySelected != initialSelectionState {
                toggleSelection(at: indexPath, in: collectionView)
            }
            
            lastSelectedIndexPath = indexPath
        }
        
        private func handlePanEnded() {
            stopAutoScroll()
            lastSelectedIndexPath = nil
        }
        
        // MARK: - Auto Scroll
        
        private func startAutoScrollIfNeeded(in collectionView: UICollectionView) {
            autoScrollTimer = CADisplayLink(target: self, selector: #selector(autoScroll))
            autoScrollTimer?.add(to: .current, forMode: .common)
        }
        
        private func stopAutoScroll() {
            autoScrollTimer?.invalidate()
            autoScrollTimer = nil
        }
        
        @objc private func autoScroll() {
            guard let collectionView = panGestureRecognizer?.view as? UICollectionView else { return }
            
            let location = panGestureRecognizer?.location(in: collectionView) ?? .zero
            let bounds = collectionView.bounds
            let scrollZoneHeight: CGFloat = 50
            
            var scrollVelocity: CGFloat = 0
            
            if location.y < scrollZoneHeight {
                // 上端近く - 上にスクロール
                let progress = (scrollZoneHeight - location.y) / scrollZoneHeight
                scrollVelocity = -progress * 10
            } else if location.y > bounds.height - scrollZoneHeight {
                // 下端近く - 下にスクロール
                let progress = (location.y - (bounds.height - scrollZoneHeight)) / scrollZoneHeight
                scrollVelocity = progress * 10
            }
            
            if scrollVelocity != 0 {
                let newOffset = CGPoint(
                    x: collectionView.contentOffset.x,
                    y: collectionView.contentOffset.y + scrollVelocity
                )
                collectionView.setContentOffset(newOffset, animated: false)
                
                // スクロール中の選択処理
                if let location = panGestureRecognizer?.location(in: collectionView) {
                    handlePanChanged(at: location, in: collectionView)
                }
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension GridView.Coordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // スクロールビューのジェスチャーと同時に認識
        return true
    }
}

// MARK: - SelectableCollectionView

private class SelectableCollectionView<Item: Identifiable>: UICollectionView {
    var columns: Int = 3
}

// MARK: - HostingCollectionViewCell

private class HostingCollectionViewCell<Content: View>: UICollectionViewCell {
    private var hostingController: UIHostingController<Content>?
    
    func configure(with content: Content) {
        if let hostingController = hostingController {
            hostingController.rootView = content
        } else {
            let hostingController = UIHostingController(rootView: content)
            hostingController.view.backgroundColor = .clear
            self.hostingController = hostingController
            
            contentView.addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // HostingControllerをリセット
        hostingController?.view.removeFromSuperview()
        hostingController = nil
    }
}
