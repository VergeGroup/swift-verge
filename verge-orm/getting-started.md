# Getting Started

```swift
struct RootState {
  
  struct Entity: DatabaseType {
              
    struct Schema: EntitySchemaType {
      let book = EntityTableKey<Book>()
      let author = EntityTableKey<Author>()
    }
    
    struct OrderTables: OrderTablesType {
      let bookA = OrderTableKey<Book>(name: "bookA")
    }
    
    var storage: Storage = .init()
  }
  
  var db = Entity()
}
```

