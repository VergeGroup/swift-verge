
public final class AsyncReentrancyDetector {
  
  var counter: Int = 0
  
  public func enter() {
    assert(counter == 0)
    counter &+= 1
  }
  
  public func leave() {
    counter &-= 1
    assert(counter == 0)
  }
}
