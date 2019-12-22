# Getter \(Selector\)



{% hint style="info" %}
TODO
{% endhint %}

VergeORM supports create MemoizeSelector from Storage or Store.

{% page-ref page="../vergestore/memoization.md" %}



```swift
let storage = Storage<RootState>(.init())
    
let id = Book.ID.init("some")

let selector = storage.entitySelector(
  entityTableSelector: { $0.db.entities.book },
  entityID: id
)

selector.value // => Optional<Book>.none (nil)

// add entity with performBatchUpdates

selector.value // => Optional<Book>.some
```

