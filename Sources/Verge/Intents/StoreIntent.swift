
public protocol StoreIntent {
  
  associatedtype State
  
  func perform() async throws    
  
}

struct StateModification: StoreIntent {
  
  func perform() async throws {
    
  }

}
