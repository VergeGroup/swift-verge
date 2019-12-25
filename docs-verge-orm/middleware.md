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

We can return `MiddlewareType` object here.  
However since it's a generic protocol, it needs to wrap up with AnyMiddleware object to return as an array.

### **struct AnyMiddleware**

```swift
public struct AnyMiddleware<Database> : MiddlewareType where Database : VergeORM.DatabaseType {

    public init<Base>(_ base: Base) where Database == Base.Database, Base : VergeORM.MiddlewareType

    public init(performAfterUpdates: @escaping (DatabaseBatchUpdateContext<Database>) -> ())

    public func performAfterUpdates(context: DatabaseBatchUpdateContext<Database>)
}
```

#### To wrap your middleware up with AnyMiddleware

```swift
public struct MyMiddleware<Database: DatabaseType>: MiddlewareType {
  ...
}

let middleware = MyMiddleware()
AnyMiddleware<Database>(middleware)
```

#### To create anonymous middleware using AnyMiddleware

```swift
AnyMiddleware<Database>(performAfterUpdates: { (context) in

  // ... any operation

})
```

## What middleware handles

* performs any operation with context after updating of batch-updates completed.
  * `MiddlewareType.performAfterUpdates`

## Create Middleware

```swift
let autoIndex = AnyMiddleware<RootState.Database>(performAfterUpdates: { (context) in

  let ids = context.insertsOrUpdates.author.all().map { $0.id }
  context.indexes.bookMiddleware.append(contentsOf: ids)

})
```

This sample code adds identifier of Author that added on batch-updates.  
This means it manages Index automatically.

Finally, returns this object on middlewares property.

```swift
let autoIndex = ...

struct Database: DatabaseType {

  ...

  var middlewares: [AnyMiddleware<RootState.Database>] {
    [
      autoIndex
    ]
  }  
}
```

