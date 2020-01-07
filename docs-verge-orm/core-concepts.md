---
description: >-
  A library to enable Object-Relational Mapping access to the value-type state
  for Swift (UIKit / SwiftUI)
---

# VergeORM Core Concepts

{% hint style="warning" %}
Sorry, this documentation is currently working in progress.
{% endhint %}

VergeORM is entity management system.

Many applications manage a lot of entities.  
Single state-tree requires work similar to creating database schema.  
The state shape is most important, otherwise performance issue will appear when your application grows.

To avoid this, we should do **Normalize** the State Shape.  
About Normalizing state shape, [Redux documentation](https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape) explains it so good.  
  
VergeORM provides several helper methods to normalize state shape.

* Supports find, insert, delete with easy plain implementations.
* Supports batch update with context, anywhere it can abort and revert to current state.

