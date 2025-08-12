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

    /// 各アイテムのコンテンツを生成するクロージャ
    let content: (Item) -> Content

    /// アイテムが表示された時のコールバック
    let onItemAppear: ((Item) -> Void)?

    /// アイテムがタップされた時のコールバック
    let onItemTap: ((Item) -> Void)?

    // MARK: - Initialization

    init(
        items: [Item],
        columns: Int,
        spacing: CGFloat = 2,
        @ViewBuilder content: @escaping (Item) -> Content,
        onItemAppear: ((Item) -> Void)? = nil,
        onItemTap: ((Item) -> Void)? = nil
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.content = content
        self.onItemAppear = onItemAppear
        self.onItemTap = onItemTap
    }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing

        let collectionView = CustomCollectionView<Item>(frame: .zero, collectionViewLayout: layout)
        collectionView.columns = columns
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator

        // セルの登録
        collectionView.register(
            HostingCollectionViewCell<Content>.self,
            forCellWithReuseIdentifier: "Cell"
        )

        return collectionView
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        guard let collectionView = uiView as? CustomCollectionView<Item> else { return }

        let previousItemsCount = context.coordinator.items.count
        context.coordinator.items = items
        collectionView.columns = columns

        // データの更新 - アイテム数が変わった場合のみ完全再読み込み
        if previousItemsCount != items.count {
            collectionView.reloadData()
        } else {
            // アイテム数が同じ場合は表示されているセルのみ更新
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        }

        // レイアウトの更新
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = spacing
            layout.minimumLineSpacing = spacing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            items: items,
            content: content,
            onItemAppear: onItemAppear,
            onItemTap: onItemTap
        )
    }
}

// MARK: - Coordinator

extension GridView {
    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
        var items: [Item]
        let content: (Item) -> Content
        let onItemAppear: ((Item) -> Void)?
        let onItemTap: ((Item) -> Void)?

        init(
            items: [Item],
            content: @escaping (Item) -> Content,
            onItemAppear: ((Item) -> Void)?,
            onItemTap: ((Item) -> Void)?
        ) {
            self.items = items
            self.content = content
            self.onItemAppear = onItemAppear
            self.onItemTap = onItemTap
        }

        // MARK: - UICollectionViewDataSource

        func numberOfSections(in _: UICollectionView) -> Int {
            return 1
        }

        func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
            return items.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! HostingCollectionViewCell<Content>

            let item = items[indexPath.item]
            let contentView = content(item)

            cell.configure(with: contentView)

            return cell
        }

        // MARK: - UICollectionViewDelegate

        func collectionView(_: UICollectionView, willDisplay _: UICollectionViewCell, forItemAt indexPath: IndexPath) {
            let item = items[indexPath.item]
            onItemAppear?(item)
        }

        func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let item = items[indexPath.item]
            onItemTap?(item)
        }

        // MARK: - UICollectionViewDelegateFlowLayout

        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
            guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
                return CGSize(width: 100, height: 100)
            }

            let columns = CGFloat((collectionView as? CustomCollectionView<Item>)?.columns ?? 3)
            let width = collectionView.bounds.width
            let totalSpacing = layout.minimumInteritemSpacing * (columns - 1)
            let itemWidth = (width - totalSpacing) / columns

            return CGSize(width: itemWidth, height: itemWidth)
        }
    }
}

// MARK: - CustomCollectionView

private class CustomCollectionView<Item: Identifiable>: UICollectionView {
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
                hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
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
