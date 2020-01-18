# 🪐 State and shape

## Using single state tree \(Not enforced\)

VergeStore uses a **single state-tree. \(Recommended\)**  
That means an object contains all of the application's state.  
With this, we can get to achieve **"single source of truth"**

```swift
struct State: StateType {
  
  var count: Int = 0
  
}
```

That state is managed by **Store**.  
It process updating the state and notify updated events to the subscribers.

{% hint style="info" %}
VergeStore does support multiple state-tree as well.  
Depending on the case, we can create another Store instance.
{% endhint %}

## Add computed property

If you have a property that does not need to be stored, that can be computed with other property.

```swift
struct State: StateType {
  
  var count: Int = 0
  
  var countText: String {
    return count.description
  }
  
}
```

## StateType protocol helps to modify

VergeStore provides `StateType` protocol as a helper.

It will be used in State struct that Store uses.  
`StateType` protocol is just providing the extensions to mutate easily in the nested state.

Just like this.

```swift
public protocol StateType {
}

extension StateType {

  public mutating func update<T>(target keyPath: WritableKeyPath<Self, T>, update: (inout T.Wrapped) throws -> Void) rethrows where T : VergeStore._VergeStore_OptionalProtocol

  public mutating func update<T>(target keyPath: WritableKeyPath<Self, T>, update: (inout T) throws -> Void) rethrows

  public mutating func update(update: (inout Self) throws -> Void) rethrows
}
```

## Normalization

**If you put the data that has relation-ship or complicated structure into state tree,   
it would be needed normalization to keep performance.  
  
Please check VergeORM module**

{% page-ref page="../docs-verge-orm/core-concepts.md" %}

{% embed url="https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape/" %}

## Subscribing the state



