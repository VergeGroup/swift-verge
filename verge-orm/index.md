# Index

## To find the entity faster, Index.

As Getting Started section touched, we can get the entities by following code.

```swift
let db = RootState.Database()

db.bookEntityTable.all()
db.bookEntityTable.find(by: <#T##VergeTypedIdentifier<Book>#>)
db.bookEntityTable.find(in: <#T##Sequence#>)
```

To do this, we need to have the Identifier of the entity and additionally, if get an array of entities, needs to manage the order of Identifier.

To do this, VergeORM provides Index function. Index manages the set of identifiers in several structures.

{% hint style="info" %}
Index meaning might be a bit different than RDB's Index.  
At least, Index manages identifiers to find the entity faster than linear search.
{% endhint %}

Currently, we have the following ways,

* OrderedIDIndex 
  * e.g. \[Book.ID\]
  * Manages identifiers in the ordered collection
* GroupByIndex
  * e.g. \[Author.ID : \[Book.ID\]\]
  * Manages identifiers that grouped by another identifier

## Register Index

Let's take a look at how to register Index.  
The whole of database is here.

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

Indexes struct describes the set of indexes. All of the indexes that are managed by VergeORM would be here.

For now, we add a simple index that ordered just like this.

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

Since Index would be updated manually, if you want to manage automatically.  
With using **Middleware**, **** it's possible.

