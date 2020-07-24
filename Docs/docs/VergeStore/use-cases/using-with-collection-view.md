---
id: using-with-collection-view
title: Using with Collection View in UIKit
sidebar_label: With Collection View in UIKit
---

:::info
This article is under work in progress.
:::

Differs with SwiftUI, the developers have to update the UI with updates partially according to state updates.

In a screen that does not have dynamic item contents, it won't be so much hard.

However, we should consider the strategy of how we update the cells when we use the dynamic list such as UICollectionView or UITableView.

This article shows you how we get to do this as a one of the strategies.

## Using multiple stores to connect with a particular UI

We have only one store that has the source of truth. This won't change.  
Additionally, we could create another store that states will be derived from the source of truth.

In the below figure, Store, ViewModel, and CellModel are Store.

![](https://user-images.githubusercontent.com/1888355/88272709-18f57180-cd14-11ea-8828-bf189f8cfbf2.png)

Let's take a look simple example with this one entity.

```swift
struct Post {
  var id: String
  var body: String
  var createdAt: Date
  var author: String
}
```

We dispaly a cell that displays `Post` entity in UICollectionView.

To be done, we will have following types.

- A Store that retains the root state to sync displaying data in all places
- A view controller that hosts an UICollectionView.
- A cell that displays data of `Post`.
- A ViewModel that provides the state to ViewController about the set of `Post`.
- A CellModel that provides the state to Cell about `Post`.

```swift
struct RootState: Equatable {
  var posts: [String : Post] = [:]
}

final class RootStore: Store<RootState, Never> {

}
```

```swift
final class PostListViewController: UIViewController {

  // Creates cells and displays by PostListViewModel.State.displayItems
}
```

```swift
final class PostListCell: UICollectionViewCell {

  private let titleLabel: UILabel = ...
  private let bodyLabel: UILabel = ...

  private var cancellable: VergeAnyCancellable?

  func bind(cellModel: PostCellModel) {

    cancellable?.cancel()

    cancellable = cellModel.sinkState(queue: .main) { [weak self] state in
      guard let self = self else { return }

      state.ifChanged(\.title) { value in
        self.titleLabel.text = value
      }

      state.ifChanged(\.body) { value in
        self.bodyLabel.text = value
      }
    }

  }

}
```

```swift
final class PostListViewModel: StoreWrapperType {

  struct State: Equatable {
    @Edge var displayItems: [PostCellModel] = []

    var cachedCellModels: [String : PostCellModel] = [:]
  }

  init(rootStore: YourRootStore) {
    ...

    fetch { items in

    }
  }

  private func fetch(completion: ([Post]) -> Void) {

  }
}
```

```swift
final class PostCellModel: Equatable, StoreWrapperType {

  static func == (lhs: PostCellModel, rhs: PostCellModel) -> Bool {
    // The object that contains independent states should be compared by pointer personality.
    // This behavior is similar with comparing instances of UIView.
    return lhs === rhs
  }

  struct State: Equatable {
    var title: String {
      "\(source.author) \(source.createdAt._psuedo_toString())"
    }
    var body: String {
      source.body
    }

    fileprivate var source: Post
  }

  let store: DefaultStore

  init(source: Post) {

    self.store = .init(initialState: .init(source: source))

  }

  func update(source: Post) {
    commit {
      $0.source = source
    }
  }
}
```
