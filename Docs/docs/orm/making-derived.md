---
id: making-derived
title: Making a Derived for the entity
sidebar_label: Making a Derived for the entity
---

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

let derived: Book.Derived = storage.derived(from: id)
```

## Get entity from Getter

```swift
let entity: Book = getter.value.wrapped
```

VergeORM supports create MemoizeSelector from Storage or Store.
