---
id: Overview
title: Overview - focusing on faster performance
sidebar_label: Overview
---

The concept of Verge Store is inspired by [Vuex](https://vuex.vuejs.org/), [Redux](https://redux.js.org/) and [ReSwift](https://github.com/ReSwift/ReSwift).

Recenlty, [facebookexperimental/Recoil](https://github.com/facebookexperimental/Recoil) has been opened.  
Atoms and Selectors similar to ours `Derived`.

Plus, releasing from so many definition of the actions. (e.g. enum)
To be more Swift's Style on the writing code.

We can do `store.myOperation()` instead of `store.dispatch(.myOperation)`

The characteristics are

- Functions that gains performance (Automatic / Manual - Memoization)
- Method based dispatching action
- Separating the code in a large app
- Emits any events that isolated from State It's for SwiftUI's onReceive\(:\)
- Logging \(Commit, Performance monitoring\)
- Binding with Combine and RxSwift
- Normalizing the state with ORM
- Multi-threading

```swift
struct State {
  var name: String = ""
  var age: Int = 0
}

enum Activity {
  case somethingHappen
}

// 🌟with UIKit
class ViewController: UIViewController {

  ...

  let store = Store<State, Activity>(initialState: .init(), logger: nil)

  ...

  func update(changes: Changes<State>) {

    changes.ifChanged(\.name) { (name) in
      nameLabel.text = name
    }

    changes.ifChanged(\.age) { (age) in
      ageLabel.text = age.description
    }

  }
}


// 🌟with SwiftUI
struct MyView: View {

  @EnvironmentObject var store: Store<State, Activity>

  var body: some View {
    Group {
      Text(store.state.name)
      Text(store.state.age)
    }
  }
}
```

## Prepare moving to SwiftUI from now with Verge

SwiftUI's concept is similar to the concept of React, Vue, and Elm. <br/>
Therefore, the concept of state management will become to be similar as well.

That is Redux or Vuex and more.

Now, almost of iOS Applications are developed on top of UIKit.<br/>
And We can't say SwiftUI is ready for top production. <br/>
However, it would change.

It's better to use the state management that fits SwiftUI from now. It's not only for that, current UIKit based applications can get more productivity as well.

## Questions?

We accept your questions about usage of Verge and something else in GitHub Issues.

日本語での質問も大丈夫です
