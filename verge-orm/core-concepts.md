# VergeORM Core Concepts

{% hint style="warning" %}
Sorry, this documentation is currently working in progress.
{% endhint %}

VergeORM is entity management system.

Many application manages much entities.  
Single state-tree means like creating database schema.  
The state shape is most important, otherwise performance issue will be appear with growing application.

Avoid this, we should do **Normalize** the State Shape.  
About Normalizing state shape, [Redux documentation](https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape) explains so good.

VergeORM provides several helper methods to normalized state shape.

* Supports find, insert, delete easily than plain implementations.
* Supports batch update with context, anywhere it can abort and revert to current state.

