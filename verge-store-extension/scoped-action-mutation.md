# Scoped Action / Mutation



{% hint style="warning" %}
WIP
{% endhint %}



```swift
dispatch(scope: \.nested) { (c) -> Void in
        
  let _: State.NestedState = c.state
  
  c.commit { state in
    let _: State.NestedState = state
    
  }
  
  c.dispatch(scope: \.optionalNested) { c in
    
    let _: State.OptionalNestedState? = c.state
    
    c.commit { state in
      let _: State.OptionalNestedState? = state
      
    }
    
  }
          
}
```

