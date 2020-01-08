---
description: >-
  A library to enable Object-Relational Mapping access to the value-type state
  for Swift (UIKit / SwiftUI)
---

# VergeORM Core Concepts

## What VergeORM is

VergeORM is a library to manage Object-Relational Mapping in the value-type struct.

It provides to store with **Normalization and accessing easier way.**

_Basically, If we do Normalization without any tool, accessing would be complicated._

The datastore can be stored anywhere because it's built by struct type.  
It allows that to adapt to state-shape already exists.

```swift
struct YourAppState: StateType {
  
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

## Store with normalization

Many applications manage a lot of entities.  
Single state-tree requires work similar to creating database schema.  
The state shape is most important, otherwise performance issue will appear when your application grows.

To avoid this, we should do **Normalize** the State Shape.  
About Normalizing state shape, [Redux documentation](https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape) explains it so good.  
  
VergeORM provides several helper methods to normalize state shape.

* Supports find, insert, delete with easy plain implementations.
* Supports batch update with context, anywhere it can abort and revert to current state.

