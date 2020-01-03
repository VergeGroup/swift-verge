# Index

## To find the entity faster, Index.

As shown in the Getting Started section, we can get entities by the following code.

```swift
let db = RootState.Database()

db.bookEntityTable.all()
db.bookEntityTable.find(by: <#T##VergeTypedIdentifier<Book>#>)
db.bookEntityTable.find(in: <#T##Sequence#>)
```

To do this, we need to manage the Identifier of the entity and additionally, to get an array of entities, we need to manage the order of Identifier.

To do this, VergeORM provides Index feature. Index manages the set of identifiers in several structures.

{% hint style="info" %}
Meaning of Index might be a bit different than RDB's Index.  
At least, Index manages identifiers to find the entity faster than linear search.
{% endhint %}

Currently, we have the following types,

* **OrderedIDIndex** 
  * e.g. \[Book.EntityID\]
  * Manages identifiers in an ordered collection
* **GroupByIndex**
  * e.g. \[Author.ID : \[Book.EntityID\]\]
  * Manages identifiers that are grouped by another identifier
* **HashIndex**
  * e.g. \[Key : Entity.EntityID\]
  * Manages identifiers with hashable keys

## Register Index

Let's take a look at how to register Index.  
The whole index is here.

```swift
struct Database: DatabaseType {

  struct Schema: EntitySchemaType {
    let book = Book.EntityTableKey()
    let author = Book.EntityTableKey()
  }

  struct Indexes: IndexesType {
    // 👋 Here!
  }

  var _backingStorage: BackingStorage = .init()
}
```

Indexes struct describes the set of indexes. All of the indexes managed by VergeORM would be here.

For now, we add a simple ordered index just like this.

```swift
struct Indexes: IndexesType {
  let allBooks = IndexKey<OrderedIDIndex<Schema, Book>>()
  // or OrderedIDIndex<Schema, Book>.Key()
}
```

With this, now we have index property on `DatabaseType.indexes`.

```swift
let allBooks = state.db.indexes.allBooks
// allBooks: OrderedIDIndex<Database.Schema, Book>
```

## Read Index

**Accessing indexes**

```swift
// Get the number of ids
allBooks.count

// Take all ids
allBooks.forEach { id in ... }

// Get the id with location
let id: Book.ID = allBooks[0]
```

**Fetch the entities from index**

```swift
let books: [Book] = state.db.entities.book.find(in: state.db.indexes.allBooks)
// This syntax looks is a bit verbose.
// We will take shorter syntax.
```

## Write Index

To write index is similar with updating entities.  
Using `performBatchUpdates` , add or delete index through the `context` .

```swift
state.db.performBatchUpdates { (context) -> Book in

  let book = Book(rawID: id.raw, authorID: Author.anonymous.id)
  context.insertsOrUpdates.book.insert(book)

  // Here 👋
  context.indexes.allBooks.append(book.id)

}
```

Since Index is updated manually here, you might want to manage it automatically.  
Using **Middleware**, _\*\*_ it's possible.

