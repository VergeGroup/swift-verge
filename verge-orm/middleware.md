# Middleware

## Perform any operation for each of all updates

Using Middleware, you can perform any operation for each of all updates.

For example,

* Manage Index according to updated entities, for each of all updates

## Register Middleware

In DatabaseType protocol, we can return the set of middlewares.   
This property would be called for each update.

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



