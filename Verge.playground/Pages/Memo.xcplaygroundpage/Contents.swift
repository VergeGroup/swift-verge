
enum Action {
  case increment
  case decrement
}

class Store<State> {

  var state: State
}
