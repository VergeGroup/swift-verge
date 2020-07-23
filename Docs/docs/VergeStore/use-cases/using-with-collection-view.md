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
