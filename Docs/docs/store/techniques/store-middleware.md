---
id: store-middleware
title: Middleware in Store
sidebar_label: Middleware in Store
---

Middleware can unify extra operations according to dispatched events from `Store`.

Here is exmaple code:

```swift
let store = DemoStore()

store.add(middleware: .unifiedMutation({ (state, _) in
  state.count += 1
}))

/* ✅ */ XCTAssertEqual(store.state.count, 0)

store.commit {
  $0.count += 1
}

/* ✅ */ XCTAssertEqual(store.state.count, 2)
```

In the case of modifying additionally with the updated state, Middleware helps us.  
This way won't increase the number of commits comparing with using subscribing self and committing.
