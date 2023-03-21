
struct LinkedList<T> {

  private var ref: LinkedListRef<T>

  public init() {
    self.ref = .init()
  }

  private mutating func copyIfNeeded() {
    guard isKnownUniquelyReferenced(&ref) == false else {
      return
    }
    let newRef = ref.copy()
    self.ref = newRef
  }

}


extension LinkedList {
  var isEmpty: Bool {
    return ref.head == nil
  }

  var count: Int {
    var count = 0
    var node = ref.head
    while node != nil {
      count += 1
      node = node?.next
    }
    return count
  }

  var elements: [T] {
    var elements: [T] = []
    var node = ref.head
    while node != nil {
      elements.append(node!.value)
      node = node?.next
    }
    return elements
  }
}

extension LinkedList {

  mutating func append(_ value: T) {

    copyIfNeeded()

    let newNode = Node(value: value)
    if ref.tail == nil {
      ref.head = newNode
      ref.tail = newNode
    } else {
      ref.tail!.next = newNode
      ref.tail = newNode
    }
  }

  @discardableResult
  mutating func removeFirst() -> T? {
    copyIfNeeded()

    if ref.head == nil {
      return nil
    }

    let removedValue = ref.head?.value
    ref.head = ref.head?.next

    if ref.head == nil {
      ref.tail = nil
    }

    return removedValue
  }
}

fileprivate final class LinkedListRef<T> {

  var head: Node<T>?
  var tail: Node<T>?

  init(head: Node<T>? = nil, tail: Node<T>? = nil) {
    self.head = head
    self.tail = tail
  }

  func copy() -> LinkedListRef<T> {
    guard let copiedHead = head?.copy() else {
      return .init()
    }

    var currentNode = copiedHead
    while currentNode.next != nil {
      currentNode = currentNode.next!
    }

    return .init(head: copiedHead, tail: currentNode)
  }

}

fileprivate final class Node<T> {
  var value: T
  var next: Node<T>?

  init(value: T, next: Node<T>? = nil) {
    self.value = value
    self.next = next
  }

  func copy() -> Node<T> {
    return Node(value: value, next: next?.copy())
  }
}
