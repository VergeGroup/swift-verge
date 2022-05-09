
public enum PrimitiveIdentifier: Hashable {
  
  case string(String)
  case int64(Int64)
  case uint64(UInt64)
  case int(Int)

}

public protocol _PrimitiveIdentifierConvertible: Hashable {
  
  var _primitiveIdentifier: PrimitiveIdentifier { get }
  
  static func _restore(from primitiveIdentifier: PrimitiveIdentifier) -> Self?
  
}

extension String: _PrimitiveIdentifierConvertible {
  
  @inline(__always)
  public var _primitiveIdentifier: PrimitiveIdentifier {
    return .string(self)
  }
  
  @inline(__always)
  public static func _restore(from primitiveIdentifier: PrimitiveIdentifier) -> Self? {
    guard case .string(let value) = primitiveIdentifier else {
      return nil
    }
    return value
  }
}

extension Int64: _PrimitiveIdentifierConvertible {
  
  @inline(__always)
  public var _primitiveIdentifier: PrimitiveIdentifier {
    return .int64(self)
  }
  
  @inline(__always)
  public static func _restore(from primitiveIdentifier: PrimitiveIdentifier) -> Self? {
    guard case .int64(let value) = primitiveIdentifier else {
      return nil
    }
    return value
  }
}

extension UInt64: _PrimitiveIdentifierConvertible {
  
  @inline(__always)
  public var _primitiveIdentifier: PrimitiveIdentifier {
    return .uint64(self)
  }
  
  @inline(__always)
  public static func _restore(from primitiveIdentifier: PrimitiveIdentifier) -> Self? {
    guard case .uint64(let value) = primitiveIdentifier else {
      return nil
    }
    return value
  }
}
extension Int: _PrimitiveIdentifierConvertible {
  
  @inline(__always)
  public var _primitiveIdentifier: PrimitiveIdentifier {
    return .int(self)
  }
  
  @inline(__always)
  public static func _restore(from primitiveIdentifier: PrimitiveIdentifier) -> Self? {
    guard case .int(let value) = primitiveIdentifier else {
      return nil
    }
    return value
  }
}
