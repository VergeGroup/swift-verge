---
id: logging
title: Logging
sidebar_label: Logging
---

## Start logging from DefaultStoreLogger

DefaultStoreLogger is the pre-implemented logger that send the logs to OSLog.
To enable logging, set the logger instance to Store's initializer.

```swift
Store<MyState, MyActivity>.init(
  initialState: ...,
  logger: DefaultStoreLogger.shared // 🤩
)
```

Mainly, we can monitor log about commit in Xcode's console and Terminal.app

```
2020-05-25 23:47:06.884304+0900 VergeStoreDemoSwiftUI[84086:2813713] [Commit] {
  "store" : "VergeStore.Store<VergeStoreDemoSwiftUI.SessionState, Swift.Never>()",
  "tookMilliseconds" : 0.19299983978271484,
  "trace" : {
    "createdAt" : "2020-05-25T14:47:06Z",
    "file" : "\/Users\/muukii\/.ghq\/github.com\/muukii\/Verge\/worktree\/space1\/Sources\/VergeStoreDemoSwiftUI\/Session.swift",
    "function" : "submitNewPost(title:from:)",
    "line" : 129,
    "name" : ""
  },
  "type" : "commit"
}
```

## Creating a customized logger

If you need a customized logger, you can create that with `StoreLogger` protocol.

```swift
public protocol StoreLogger {

  func didCommit(log: CommitLog)

  func didCreateDispatcher(log: DidCreateDispatcherLog)
  func didDestroyDispatcher(log: DidDestroyDispatcherLog)
}
```
