---
id: viewmodel-in-uikit
title: Using a ViewModel in UIKit
sidebar_label: Using a ViewModel in UIKit
---

:::info
This article is under work in progress.
:::

This article will tell you how we use Verge and MVVM architecture in UIKit.

## Example App : Todo List

### Entitiy

```swift
struct Task {
  let id: String
  let title: String
}
```

### ViewModel

```swift
final class TodoListViewModel: StoreComponentType {

  /// Equatable is not required. But if we have it gains better performance.
  struct State: Equatable {
    var items: [Taks] = []

    var numberOfItems: Int {
      items.count
    }
  }

  /// A store that retains a latest state for target view-controller.
  let store: DefaultStore

  init() {

    self.store = .init(
      initialState: .init()
    )
  }

  func addTask(_ task: Task) {
    commit {
      $0.items.append(task)
    }
  }

}
```

### ViewController

```swift

final class TodoListViewController: UIViewController {

  private let collectionView: UICollectionView
  private let totalCountLabel: UILabel

  private var cancellables: Set<VergeAnyCancellable> = .init()

  init(viewModel: TodoListViewModel) {
    ...

    viewModel.sinkState { [weak self] state in
      guard let self = self else { return }

      state.ifChanged(\.numberOfItems) { value in
        self.totalCountLabel.text = "\(value)"
      }

      state.ifChanged(\.items) { value in
        // update collectionView
      }

    }
    .store(in: &cancellables)
  }

}

```
