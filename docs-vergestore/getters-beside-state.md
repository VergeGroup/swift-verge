# 🛸 Computed property on State

## Computed Property on State

States may have a property that actually does not need to be stored property.  
In that case, we can use computed property.

Although, we should take care of the cost of the computing to return value in that.  
What is that case? Followings explains that.

{% hint style="info" %}
Getters concept is inspired from Vuex Getter.  
[https://vuex.vuejs.org/guide/getters.html](https://vuex.vuejs.org/guide/getters.html)
{% endhint %}

For example, there is itemsCount.

```swift
struct State: StateType {
  var items: [Item] = []
    
  var itemsCount: Int = 0
}
```

In order to become itemsCount dynamic value, it needs to be updated with updating items like this.

```swift
struct State: StateType {
  var items: [Item] = [] {
    didSet {
      itemsCount = items.count
    }
  }
    
  var itemsCount: Int = 0
}
```

We got it, but we don't think it's pretty simple. Actually we can do this like this.

```swift
struct State: StateType {
  var items: [Item] = [] {
  
  var itemsCount: Int {
    items.count
  }
}
```

With this, it did get to be more simple.

```swift
struct State: StateType {
  var items: [Item] = []
  
  var processedItems: [ProcessedItem] {
    items.map { $0.doSomeExpensiveProcessing() }
  }
}
```

As an example,  Item can be processed with the something operation that takes expensive cost.  
We can replace this example with filter function.  
  
This code looks is very simple and it has got data from source of truth. Every time we can get correct data.  
However we can look this takes a lot of the computing resources.  
In this case, it would be better to use didSet and update data.

```swift
struct State: StateType {
  var items: [Item] = [] {
    didSet {
      processedItems = items.map { $0.doSomeExpensiveProcessing() }
    }
  }
  
  var processedItems: [ProcessedItem] = []
}
```

However, as we said, this approach is not simple.  
And this can not handle easily a case that combining from multiple stored property.  
  
Next introduces one of the solutions.

## Computed Properties

VergeStore has a way of providing computed property with caching to reduce taking computing resource.

Keywords are:

* ExtendedStateType
* ExtendedType
* Field.Computed&lt;T&gt;

Above State code can be improved like following.

```swift
struct State: ExtendedStateType {

  var name: String = ...
  var items: [Int] = []
  
  struct Extended: ExtendedType {
    let filteredArray = Field.Computed<[Int]> {
      $0.items.filter { $0 > 300 }
    }
    .ifChanged(selector: \.largeArray)
  }
}
```

Accessing

```swift
let store: MyStore<State, Never> = ...

let changes = store.changes

let result: [Int] = changes.computed.filteredArray
```

`store.computed.filteredArray` will be updated only when items updated.  
Since the results are stored as a cache, we can take value without computing.

Followings are the steps describes when it computes while paying the cost.

```swift
let store: MyStore<State, Never> = ...

// It computes
store.changes.computed.filteredArray

// no computes because results cached with first-time access
store.changes.computed.filteredArray

// State will change but no affects items
store.commit {
  $0.name = "Muukii"
}

// no computes because results cached with first-time access
store.changes.computed.filteredArray

// State will change with it affects items
store.commit {
  $0.items.append(...)
}

// It computes new value
store.changes.computed.filteredArray
```

