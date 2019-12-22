# Tips

## Access to DB partially

We may want to create common accessing code with using protocol if we have multiple database object.

```swift
protocol Partial {
  var author: Author.EntityTableKey { get }
}

struct Database: DatabaseType {
  
  struct Schema: EntitySchemaType, Partial {
    let book = Book.EntityTableKey()
    let author = Author.EntityTableKey()
  }
  
  struct Indexes: IndexesType {
  }
    
  var _backingStorage: BackingStorage = .init()
}
```

```swift
func access<DB: DatabaseType>(db: DB) -> Int where DB.Schema : Partial {
  db.entities.author.all().count
}
```

Inside of access function, it supports only accessing to entity `Partial` protocol has.

