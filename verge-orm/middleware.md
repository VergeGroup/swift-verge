# Middleware

## Perform any operation by all of updates

Using Middleware, it can perform any operations by all of updates.

For example,

* Manages Index with updating entities by all updates

## Register Middleware

In DatabaseType protocol, we can return the set of middlewares.   
This property would be called each update.

```swift
struct Database: DatabaseType {
  
  ...
  
  var middlewares: [AnyMiddleware<RootState.Database>] {
    [
      // Here
    ]
  }  
}
```



