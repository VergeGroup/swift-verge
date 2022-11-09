# ``VergeORM``

It provides the function that manages performant many entity objects. Technically, using Normalization.

In the application that uses many entity objects, we sure highly recommend using such as ORM using Normalization.

About more detail, https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape

## Core Concepts

VergeORM is a library to manage Object-Relational Mapping in the value-type struct.

It provides to store with Normalization and accessing easier way. Basically, If we do Normalization without any tool, accessing would be complicated.

The datastore can be stored anywhere because it’s built by struct type. It allows that to adapt to state-shape already exists.

```swift
struct YourAppState {

  // VergeORM's datastore
  struct Database: DatabaseType {

    ...
    // We will explain this later.
  }

  // Put Database anywhere you'd like
  var db: Database = .init()

  ... other states
}
```

### Stores data with normalization

Many applications manage a lot of entities. Single state-tree requires work similar to creating database schema. The state shape is most important, otherwise performance issue will appear when your application grows.

‌ To avoid this, we should do **Normalize** the State Shape. About Normalizing state shape, [Redux documentation](https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape) explains it so good. VergeORM provides several helper methods to normalize state shape.

- Supports find, insert, delete with easy plain implementations.
- Supports batch update with context, anywhere it can abort and revert to current state.

## Getting Started

### Create Database struct

**Database struct** contains the tables for each Entity. As a struct object, that allows to manage history and it can be embedded on the state that application uses. ‌

- Database struct
    - Book entity
    - Author entity

### Add DatabaseType protocol to your database struct

```swift
struct Database: DatabaseType {
}
```

`DatabaseType` protocol has several constraints and provides functions with that. To satisfy those constraints, make it like following

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

By conforming to `EntityType` protocol, it can be used by Database as Entity. It needs `rawID` and you can set whatever type your Entity needs.

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

You can get aEntityTable object for Book. And then you can use these methods.

```swift
bookEntityTable.all()
bookEntityTable.find(by: <#T##VergeTypedIdentifier<Book>#>)
bookEntityTable.find(in: <#T##Sequence#>)
```

> 💡 These syntax are realized by Swift’s dynamicMemberLookup. If you have curiosity, please check out the source-code.
> 

## Update Database

To update Database object(Insert, Update, Delete), use `performbatchUpdates` method.

```swift
db.performBatchUpdates { (context) in
  // Put the updating code here
}
```

Example:

```swift
db.performBatchUpdates { (context) in
  let book = Book(rawID: "some")
  context.book.insert(book)
}

// db.entities.book.count == 1
```

<!--## Topics-->

<!---->
<!--### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->-->
<!---->
<!--- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->-->
