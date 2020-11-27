
import UIKit
import VergeStore

final class DemoCollectionViewController: UIViewController, UICollectionViewDelegateFlowLayout {

  @IBOutlet weak var collectionView: UICollectionView!

  private let viewModel = DemoCollectionViewModel()
  private var subscription: VergeAnyCancellable?

  override func viewDidLoad() {
    super.viewDidLoad()

    let dataSource = UICollectionViewDiffableDataSource<String, DemoCollectionCellModel>(
      collectionView: collectionView,
      cellProvider: { collectionView, indexPath, cellModel in
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DemoCell", for: indexPath) as! DemoCollectionCell
        cell.attach(cellModel: cellModel)
        return cell
      })

    collectionView.dataSource = dataSource
    collectionView.delegate = self

    subscription = viewModel.sinkState { (state) in

      state.ifChanged(\.displayItems) { items in
        var snapshot = NSDiffableDataSourceSnapshot<String, DemoCollectionCellModel>()

        snapshot.appendSections(["first"])
        snapshot.appendItems(items)

        dataSource.apply(snapshot)
      }

    }
  }

  @IBAction func onTapLoadButton(_ sender: Any) {

    viewModel.fetchItems {

    }

  }

  @IBAction func onTapReductButton(_ sender: Any) {
    viewModel.reductAllData()
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

    return CGSize(width: collectionView.bounds.width / 6, height: 50)
  }

}

final class DemoCollectionCell: UICollectionViewCell {

  private var subscription: VergeAnyCancellable?

  @IBOutlet weak var valueLabel: UILabel!

  func attach(cellModel: DemoCollectionCellModel) {

    subscription?.cancel()

    subscription = cellModel.sinkState { [weak self] state in
      guard let self = self else { return }

      state.ifChanged(\.text) { text in
        self.valueLabel.text = text
      }

    }

  }
}

final class DemoCollectionViewModel: StoreComponentType, Equatable {

  static func == (lhs: DemoCollectionViewModel, rhs: DemoCollectionViewModel) -> Bool {
    // ViewModel must be compared with pointer personality only.
    lhs === rhs
  }

  struct State: Equatable {
    var displayItems: [DemoCollectionCellModel] = []
  }

  let store: DefaultStore = .init(initialState: .init())

  private let cacheStorage: CachedMapStorage<Post, DemoCollectionCellModel> = .init(keySelector: \.id)

  init() {

  }

  func fetchItems(completion: @escaping () -> Void) {

    func generateDummy() -> [Post] {
      (0..<10).map { _ in
        Post(name: .randomEmoji())
      }
    }

    // Fake asynchronous operation like networking
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {

      let items = generateDummy()

      let result = items.cachedMap(using: self.cacheStorage, makeNew: { (post) in
        DemoCollectionCellModel(post: post)
      },
      update: { post, cellModel in
        cellModel.update(post: post)
      })

      self.commit {
        $0.displayItems += result
      }

      completion()

    }

  }

  func reductAllData() {
    state.displayItems.forEach { cellModel in
      cellModel.reduct()
    }
  }

}

final class DemoCollectionCellModel: StoreComponentType, Hashable {

  static func == (lhs: DemoCollectionCellModel, rhs: DemoCollectionCellModel) -> Bool {
    lhs === rhs
  }

  func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }

  struct State: Equatable {
    var post: Post?

    var text: String {
      post?.name ?? "❌"
    }
  }

  let store: DefaultStore

  init(post: Post) {

    store = .init(initialState: .init(post: post))
  }

  func update(post: Post) {
    commit {
      $0.post = post
    }
  }

  func reduct() {
    commit {
      $0.post = nil
    }
  }

}

struct Post: Hashable {

  let id: UUID = UUID()

  var name: String = .randomEmoji()
}

extension String{
  static func randomEmoji() -> String{
    let range = 0x1F601...0x1F64F
    let ascii = range.lowerBound + Int(arc4random_uniform(UInt32(range.count)))

    var view = UnicodeScalarView()
    view.append(UnicodeScalar(ascii)!)

    let emoji = String(view)

    return emoji
  }
}
