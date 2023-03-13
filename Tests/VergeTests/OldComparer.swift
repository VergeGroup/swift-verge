/// A component that compares an input value.
/// It can be combined with other comparers.
public struct Comparer<Input> {

  public static var alwaysFalse: Self {
    .init { _, _ in false }
  }

  private let _equals: (Input, Input) -> Bool

  /// Creates an instance
  ///
  /// - Parameter equals: Return true if two inputs are equal.
  public init(
    _ equals: @escaping (Input, Input) -> Bool
  ) {
    self._equals = equals
  }

  /// It compares the value selected from passed selector closure
  /// - Parameter selector:
  public init<T: Equatable>(selector: @escaping (Input) -> T) {
    self.init { a, b in
      selector(a) == selector(b)
    }
  }

  public init<T>(selector: @escaping (Input) -> T, equals: @escaping (T, T) -> Bool) {
    self.init { a, b in
      equals(selector(a), selector(b))
    }
  }

  public init<T>(selector: @escaping (Input) -> T, comparer: Comparer<T>) {
    self.init { a, b in
      comparer._equals(selector(a), selector(b))
    }
  }

  /// Make Combined comparer
  /// - Parameter comparers:
  public init(and comparers: [Comparer<Input>]) {
    self.init { pre, new in
      for filter in comparers {
        guard filter._equals(pre, new) else {
          return false
        }
      }
      return true
    }
  }

  /// Make Combined comparer
  /// - Parameter comparers:
  public init(or comparers: [Comparer<Input>]) {
    self.init { pre, new in
      for filter in comparers {
        if filter._equals(pre, new) {
          return true
        }
      }
      return false
    }
  }

  public func equals(_ lhs: Input, _ rhs: Input) -> Bool {
    _equals(lhs, rhs)
  }

  /// Returns an curried closure
  public func curried() -> (_ lhs: Input, _ rhs: Input) -> Bool {
    _equals
  }

}

extension Comparer where Input : Equatable {
  public init() {
    self.init(==)
  }

  public static var usingEquatable: Self {
    return .init(==)
  }
}

extension Comparer {

  public func and(_ otherComparer: () -> Comparer) -> Comparer {
    .init(and: [
      self,
      otherComparer()
    ])
  }

  public func or(_ otherComparer: () -> Comparer) -> Comparer {
    .init(or: [
      self,
      otherComparer()
    ])
  }

}
