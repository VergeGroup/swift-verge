# Fragment&lt;State&gt;

{% embed url="https://github.com/muukii/Verge/pull/45" %}

## Fragment helps compare if state was updated

In a single state tree, comparing for reducing the number of updates would be most important for keep performance.  
However, implementing Equatable is not easy basically.  
Instead, adding a like flag that indicates updated itself, it would be easy

## Actually, we need to get to flag that means different, it no need to be equal

Actually, we need to get to flag that means **different**, it no need to be **equal**.

## Fragment does embed state with flag

Now we can use Fragment struct that is a container for wrapping inside state up.  
With dynamicMemberLookup, we can access the properties without new property.  
Fragment has `UpdatedMarker`, we can compare if the state was updated with this.

```swift
struct YourState {
  var name: String = ...
}

struct AppState {

  var yourState: Fragment<YourState> = .init(.init())
}

appState.yourState.name // accessing with dynamic-member-lookup
```

