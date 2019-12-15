# Getting Started

### Create Database struct

**Database struct** contains the tables for each the Entity.  
As a struct object, that allows to manage history and it can be embedded on the state that application uses.

* Database struct
  * Book entity
  * Author entity

{% hint style="info" %}
WIP
{% endhint %}



```swift
struct SessionState: StateType {
  
  struct Database: DatabaseType {
    
    struct Schema: EntitySchemaType {
      
      let post = Entity.Post.EntityTableKey()
      let user = Entity.User.EntityTableKey()
      let comment = Entity.Comment.EntityTableKey()
    }
    
    struct OrderTables: OrderTablesType {
      let userIDs = Entity.User.OrderTableKey(name: "userIDs")
      let postIDs = Entity.Post.OrderTableKey(name: "postIDs")
    }
       
    var _backingStorage: DatabaseStorage<SessionState.Database.Schema, SessionState.Database.OrderTables> = .init()
  }
    
  var db: Database = .init()
  
  var postIDsByUser: [Entity.User.ID : [Entity.Post.ID]] = [:]
}
```

