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

We should know this, **Flux can't work well without something else rendering engine that works updating UI partially.**

So this article shows you how we get to use Flux in UIKit based application.

:::caution
the strategy what this article shows is a one of the strategies we can consider. we might find another better way.
:::

## Put a view model where we need to update UI partially

As above said, UIKit handles components directly displayed on the device's screen.

Such as UIView contains CALayer to store backing-storage that contains something data (e.g. bitmap-data) to render themselves.  
That means creating and recreating them is quite expensive.  
We can see that also from reusing UIView based cells in UICollectionView and UITableView.  
To keep a better performance, we should reduce recreating UIView.

So how we do this in flux?
Actually, we have the only way to handle manually according to the state.
Unless using something view-recycling library.

As possible as to keep using an instance of UIView that created once, injects the state from outside.

ViewModel or something else objects that retain a state help that.  
That retains a state derived from the root state and local state for a component to restore the latest state in another instance of UIView.

## Big picture of the app

It's going to show you the figure for the big picture of the app.

### Legends

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

### Events / Data Flow

![image](https://user-images.githubusercontent.com/1888355/89130062-03b2eb00-d53d-11ea-8cba-de6aabfaa2a0.png)

### Application architecture

![image](https://user-images.githubusercontent.com/1888355/89130073-10cfda00-d53d-11ea-9721-f8e5f6103034.png)
