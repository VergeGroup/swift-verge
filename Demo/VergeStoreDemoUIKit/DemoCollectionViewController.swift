
import UIKit
import VergeStore

final class DemoCollectionViewController: UIViewController {

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
        Post(name: "")
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
        $0.displayItems = result
      }

      completion()

    }

  }

}

final class DemoCollectionCellModel: StoreComponentType, Equatable {

  static func == (lhs: DemoCollectionCellModel, rhs: DemoCollectionCellModel) -> Bool {
    lhs === rhs
  }

  struct State: Equatable {
    var post: Post
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

}

struct Post: Hashable {

  let id: UUID = UUID()

  var name: String
}
