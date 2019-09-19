# Verge - Neue (SwiftUI / UIKit)

> ⚠️ Currently in progress

Latest released Verge => [`master` branch](https://github.com/muukii/Verge/tree/master)

**Verge - Neue** is an unidirectional-data-flow framework.

<img width="1200" src="./graph@2x.png">

[Link to Demo Application Video](https://www.notion.so/muukii/Verge-Demo-Application-9bf28b56a61e468d9462d6100d721380)

## Architecture

The sources are in `VergeNeue` directory.

**Demo Application** is in `VergeNeueDemo` directory.<br>
Demo implementations are super experimentally code. I think there are no best practices. So these may be updated. 

* Store / ScopedStore
* Reducer
  * Mutation -> Change state
  * Action -> Mutation -> Change state
  * Contains dependencies what product needed
  
**🏬 Store**
  
```swift
let rootStore = Store(
  state: RootState(),
  reducer: RootReducer()
)
```

**📦 State**

```swift
struct RootState {
     
  var count: Int = 0
  
  var photos: [Photo.ID : Photo] = [:]
  var comments: [Commenet.ID : Comment] = [:]
  
}
```

<details><summary>struct Photo</summary>
<p>

```swift
struct Photo: Identifiable {
  
  let id: String
  let url: URL
}
```
</p>
</details>

<details><summary>struct Comment</summary>
<p>

```swift
struct Comment: Identifiable {
  
  let id: String
  let photoID: Photo.ID
  let body: String
 
}
```
</p>
</details>


**Use State**

```swift
struct HomeView: View {
  
  @ObservedObject var store: Store<RootReducer>
      
  var body: some View {
    NavigationView {
      List(store.state.photos) { (photo) in
        NavigationLink(destination: PhotoDetailView(photoID: photo.id)) {
          Cell(photo: photo, comments: self.sessionStore.state.comments(for: photo.id))
        }
      }
      .navigationBarTitle("Home")
    }
    .onAppear {
      self.sessionStore.dispatch { $0.fetchPhotos() }
    }
  }
}
```

<details><summary>PhotoDetailView</summary>
<p>

```swift
struct PhotoDetailView: View {    
  let photoID: Photo.ID
  
  @EnvironmentObject var sessionStore: SessionStateReducer.StoreType
  @State private var draftCommentBody: String = ""
  
  private var photo: Photo {
    sessionStore.state.photosStorage[photoID]!
  }
      
  var body: some View {
    VStack {
      Text("\(photo.id)")
      TextField("Enter comment here", text: $draftCommentBody)
        .padding(16)
      Button(action: {
        
        guard self.draftCommentBody.isEmpty == false else { return }
        
        self.sessionStore.dispatch {
          $0.submitComment(body: self.draftCommentBody, photoID: self.photoID)
        }
        self.draftCommentBody = ""
        
      }) {
        Text("Submit")
      }
    }
  }
}
```

</p>
</details>

**💥 Reducer**

We can choose class or struct depends on use cases.

Store uses Reducer as an instance.<br>
This means Reducer can have some dependencies. (e.g Database, API client)

Firstly, In order to implement Reducer, Use `ReducerType` on the object.<br>
And then, `ReducerType` needs a type of state to update the state with type-safety.

```swift
class RootReducer: ReducerType {
  
  typealias TargetState = RootState
```

**Define Mutation**

The only way to actually change state in a Verge store is by committing a mutation.<br>
Define a function that returns `Mutation` object. That expresses that function is `Mutation`

`Mutation` object is simple struct that has a closure what passes current state to change it.

> `Mutation` does not run asynchronous operation.

```swift
extension RootReducer: ReducerType {
  func syncIncrement(adding number: Int) -> Mutation {
    return .init {
      $0.count += number
    }
  }
}
```

**Commit Mutation**

```swift
store.commit { $0.syncIncrement() }
```

---

**Define Action**

`Action` is similar to `Mutation`.<br>
`Action` can contain arbitrary asynchronous operations.

To commit Mutations inside Action, Use `context.commit`.


```swift
extension RootReducer: ReducerType {
  func asyncIncrement() -> Action<Void> {
    return .init { context in
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        context.commit { $0.syncIncrement() }
      }
    }
  }
}
```

**Dispatch Action**

```swift
store.dispatch { $0.asyncIncrement() }
```

<details><summary>More sample Reducer implementations</summary>
<p>

```swift
 func submitComment(body: String, photoID: Photo.ID) -> Action<Void> {
    return .init { context in
      
      let comment = Comment(photoID: photoID, body: body)
      context.commit { _ in
        .init {
          $0.commentsStorage[comment.id] = comment
        }
      }
      
    }
  }
```

</p>
</details>

## Advanced Informations

**ScopedStore**

`ScopedStore` is a node object detached from `Store`<br>
It initializes with `Store` as parent store and WritableKeyPath to take fragment of parent store's state.

Its side-effects dispatch and commit affects parent-store.<br>
And receives parent-store's side-effects 

**Integration between multiple stores**

// TODO:

**Integration Verge with External DataStore (e.g CoreData)**

// TODO:

## Installation

Currently it supports only CocoaPods.

In Podfile

```
pod 'VergeNeue'
```

## Author

Hiroshi Kimura (Muukii) <muukii.app@gmail.com>