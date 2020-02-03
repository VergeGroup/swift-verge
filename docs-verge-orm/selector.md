# Getter \(Selector\)

## To create getter, Add DatabaseEmbedding protocol to your state-tree.

```swift
struct RootState: DatabaseEmbedding {

  static let getterToDatabase: (RootState) -> RootState.Database = { $0.db }

  struct Database: DatabaseType {
    ...       
  }

  var db = Database()
}
```

## Create getter from entity id

```swift
let id = Book.EntityID.init("some")

let getter = storage.entityGetter(
  from: id
)
```

## Get entity from Getter

```swift
getter.value
```

## Subscribe getter

```swift
getter.addDidUpdate { (entity) in

}
```

VergeORM supports create MemoizeSelector from Storage or Store.

{% page-ref page="../docs-vergestore/memoization.md" %}

