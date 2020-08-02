---
id: using-in-uikit
title: Use Verge in UIKit with MVVM architecture
sidebar_label: Use Verge in UIKit with MVVM architecture
---

## Application uses a single source of truth and view models

As we know about Flux, Views basically displays itself according to a state.  
And that state is a single source of truth.

However, it's so hard to get to use this strategy in UIKit based applications.  
Because they don't have functions to update UI partially, it's like manipulating the DOM tree directly in a web application by the developer's implementations.

We should know this, Flux can't work without something else rendering engine that works updating UI partially.

So this article shows you how we get to use Flux in UIKit based application.

Attention: the strategy what this article shows is a one of the strategies we can consider. we might find another better way.

## Put a view model where we need to update UI partially

// WIP

## Legends

- **Store**
  - `Store` / `StoreComponentType`
  - It retains the source of truth in the application.
- **ViewModel**
  - ViewModel object
  - It retains a state of a target view.
    The state contains a derived state from the source of truth and local state that only used from the target view.
- **View**
  - It's an object sort of UIKit.
    UIView, UITableViewCell, UICollectionViewCell even UIViewController.

![image](https://user-images.githubusercontent.com/1888355/89129991-a159ea80-d53c-11ea-96b2-643eb2b9b125.png)

## Events / Data Flow

![image](https://user-images.githubusercontent.com/1888355/89130062-03b2eb00-d53d-11ea-8cba-de6aabfaa2a0.png)

## Application architecture

![image](https://user-images.githubusercontent.com/1888355/89130073-10cfda00-d53d-11ea-9721-f8e5f6103034.png)
