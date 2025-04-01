
extension StoreDriverType {
  
  public func run<Intent: AsyncStoreIntent>(
    _ intent: Intent
  ) where Intent.State == Self.TargetStore.State {    
    Task {
      try await intent.perform()
    }
  }
  
  public func run<Intent: StoreIntent>(
    _ intent: Intent
  ) throws where Intent.State == Self.TargetStore.State {
    try intent.perform()
  }
}

public protocol AsyncStoreIntent {
  
  associatedtype State
  
  func perform() async throws    
  
  typealias Target = StoreIntentTarget<State>
}

public protocol StoreIntent {
  
  associatedtype State
  
  func perform() throws    
  
  typealias Target = StoreIntentTarget<State>
}

struct StateModification: AsyncStoreIntent {    
  typealias State = MyState
  
//  @Target var state: MyState
  
  func perform(@Target state: @Target<MyState>) async throws {

  }

}

struct MyState {
  
}

@propertyWrapper
public struct StoreIntentTarget<State> {
  
  public var wrappedValue: State {
    get {
      
    }
    nonmutating set {
      
    }
  }
  
  public init(wrappedValue: State) {
  }
  
}
