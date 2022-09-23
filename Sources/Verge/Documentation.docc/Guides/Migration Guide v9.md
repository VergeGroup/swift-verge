# Changes in v9

## Store requires Equatable State

From v8 complex implementations, v9 becomes it requires Equatable to State associated with Store, Changes, Derived and what else related.

Then Verge v9 now dropped lots of implementations and overloads covering cases if the state don’t have Equatable.

## Store can have multiple databases

Now, Store has `databases` accessor that allows us to read database.
`databases` is `DatabaseDynamicMembers` which provides property following to State shape.
This looks up member only type of `DatabaseType`

```swift
@dynamicMemberLookup
public struct DatabaseDynamicMembers<Store: StoreType> {
  
  unowned let store: Store
  
  init(store: Store) {
    self.store = store
  }

  public subscript<Database: DatabaseType>(dynamicMember keyPath: KeyPath<Store.State, Database>) -> DatabaseContext<Store, Database> {
    .init(keyPath: keyPath, store: store)
  }
  
}
```

## Use new syntax for creating Field.Computed

As you know, Changes supports memoized-computed-property.
That can be done writing `Field.Computed`

Now its writing syntax will change.

```swift
let filteredArray = Field.Computed(
  .map(
    using: { $0.largeArray },
    transform: { $0.filter { $0 > 300 } }
  )
)
```

`using` specifies the dependencies which used from `transform` function.
`transform` function will create a new value from given dependencies provided from `using` function.

## Detail changes

- Dropped complex implementations related to performance tunings
- Stopped using cache to return Derived internally.
- Deleted `batchCommit`

From v8 complex implementations, v9 becomes it requires Equatable to State associated with Store, Changes, Derived and what else related.

Then Verge v9 now dropped lots of implementations and overloads covering cases if the state don’t have Equatable.
