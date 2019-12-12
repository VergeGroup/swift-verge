# Getting Started

```swift
struct RootState {
  
  struct Entity: DatabaseType {
              
    struct Schema: EntitySchemaType {
      let book = MappingKey<Book>()
      let author = MappingKey<Author>()
    }
    
    struct OrderTables: OrderTablesType {
      let bookA = OrderTablePropertyKey<Book>(name: "bookA")
    }
    
    var storage: Storage = .init()
  }
  
  var db = Entity()
}
```

