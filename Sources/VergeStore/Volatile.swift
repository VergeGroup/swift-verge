
import Foundation

public protocol VolatileType {
  associatedtype State
  
  var box: Volatile<State> { get set }
  var unsafelyUnwrap: State { get set }
}

public enum Volatile<State>: VolatileType {
  
  case some(State)
  case none
  
  public var unsafelyUnwrap: State {
    get {
      switch self {
      case .none:
        fatalError()
      case .some(let state):
        return state
      }
    }
    mutating set {
      self = .some(newValue)
    }
  }
  
  public var box: Volatile<State> {
    get {
      self
    }
    mutating set {
      self = newValue
    }
  }
}
