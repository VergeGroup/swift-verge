
import Foundation

public struct Indexed<IndexKey: Hashable, Element> {

  public private(set) var innerTable: [IndexKey : Element] = [:]

  private let indexKeySelector: (Element) -> IndexKey

  public var isEmpty: Bool {
    _read { yield innerTable.isEmpty }
  }

  public init(indexKeySelector: @escaping (Element) -> IndexKey) {
    self.indexKeySelector = indexKeySelector
  }

  public init<C: Sequence>(indexKeySelector: @escaping (Element) -> IndexKey, initialElements: C) where C.Element == Element {
    self.init(indexKeySelector: indexKeySelector)
    self.add(initialElements)
  }

  public mutating func add<C: Sequence>(_ elements: C) where C.Element == Element {
    elements.forEach { element in
      let key = indexKeySelector(element)
      innerTable[key] = element
    }
  }

  public mutating func add(_ element: Element) {
    let key = indexKeySelector(element)
    innerTable[key] = element
  }

  public mutating func remove(_ element: Element) {
    let key = indexKeySelector(element)
    innerTable.removeValue(forKey: key)
  }

  public mutating func remove(forKey indexKey: IndexKey) {
    innerTable.removeValue(forKey: indexKey)
  }

  public subscript(_ key: IndexKey) -> Element? {
    _read {
      yield innerTable[key]
    }
    _modify {
      yield &innerTable[key]
    }
  }

}
