import Verge

/**
 
 https://whimsical.com/async-verge-egKmtKD8JakCtHB3TrKEz
 */
open class AsyncStore<State, Activity>: CustomReflectable {
  
  public init(
    name: String? = nil,
    initialState: State,
    logger: StoreLogger? = nil,
    _ file: StaticString = #file,
    _ line: UInt = #line
  ) {
        
  }
  
  public var customMirror: Mirror {
    return Mirror(
      self,
      children: KeyValuePairs.init(
        dictionaryLiteral:
          ("", "")
//          ("stateVersion", state.version),
//        ("middlewares", middlewares)
      ),
      displayStyle: .class
    )
  }
  
}
