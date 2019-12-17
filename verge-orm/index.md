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



