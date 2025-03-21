
public protocol StoreIntent {
  
  associatedtype State
  
  func perform() async throws    
  
  typealias Target = StoreIntentTarget<State>
}

struct StateModification: StoreIntent {    
  
  @Target var state: MyState
  
  func perform() async throws {
    
  }

}

struct MyState {
  
}

@propertyWrapper
public struct StoreIntentTarget<State> {
  
  public var wrappedValue: State {
    get {
      
    }
    set {
      
    }
  }
  
  public init(wrappedValue: State) {
  }
  
}
