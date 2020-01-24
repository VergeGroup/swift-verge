# Getting Started

## Create Database struct

**Database struct** contains the tables for each Entity.  
As a struct object, that allows to manage history and it can be embedded on the state that application uses.

* Database struct
  * Book entity
  * Author entity

### Add DatabaseType protocol to your database struct

```swift
struct Database: DatabaseType {
}
```

`DatabaseType` protocol has several constraints and provides functions with that.  
To satisfy those constraints, make it like following

```swift
struct Database: DatabaseType {

  struct Schema: EntitySchemaType {

  }

  struct Indexes: IndexesType {

  }

  var _backingStorage: BackingStorage = .init()
}
```

### Register EntityTable

As an example, suppose we have Book and Author entities.

```swift
struct Book: EntityType {

  typealias IdentifierType = String

  var entityID: EntityID {
    .init(rawID)
  }

  let rawID: String
}

struct Author: EntityType {

  typealias IdentifierType = String

  var entityID: EntityID {
    .init(rawID)
  }

  let rawID: String
}
```

By conforming to `EntityType` protocol, it can be used by Database as Entity.  
It needs `rawID` and you can set whatever type your Entity needs.

And then, add these entities to Schema object.

```swift
struct Database: DatabaseType {

  struct Schema: EntitySchemaType {
    let book = Book.EntityTableKey()
    let author = Book.EntityTableKey()
  }

  struct Indexes: IndexesType {
    // In this time, we don't touch here.
  }

  var _backingStorage: BackingStorage = .init()
}
```

Finally, you can use Database object like this.

```swift
let db = RootState.Database()

let bookEntityTable: EntityTable<Book, Read> = db.entities.book
```

You can get a`EntityTable` object for Book.  
And then you can use these methods.

```swift
bookEntityTable.all()
bookEntityTable.find(by: <#T##VergeTypedIdentifier<Book>#>)
bookEntityTable.find(in: <#T##Sequence#>)
```

{% hint style="info" %}
These syntax are realized by Swift's dynamicMemberLookup.  
If you have curiosity, please check out the source-code.
{% endhint %}

## Update Database

To update Database object\(Insert, Update, Delete\), use `performbatchUpdates` method.

```swift
db.performBatchUpdates { (context) in
  // Put the updating code here
}
```

```swift
db.performBatchUpdates { (context) in
  let book = Book(rawID: "some")
  context.book.insert(book)
}

// db.entities.book.count == 1
```

