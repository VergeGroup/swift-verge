
import Foundation

@_spi(Internal)
public final class KeyObject<Content: Hashable>: NSObject, NSCopying {

  public func copy(with zone: NSZone? = nil) -> Any {
    return KeyObject(content: content)
  }

  public let content: Content

  public init(content: consuming Content) {
    self.content = content
  }

  public override var hash: Int {
    content.hashValue
  }

  public override func isEqual(_ object: Any?) -> Bool {

    guard let other = object as? KeyObject<Content> else {
      return false
    }

    guard content == other.content else { return false }

    return true
  }

}
