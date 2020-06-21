
import Foundation
import RealmSwift
import Combine
import CombineExt

extension Realm {

  public func throwableWrite<Result>(_ block: (Realm) throws -> Result) throws -> Result {
    do {
      beginWrite()
      let result = try block(self)
      try commitWrite()
      return result
    } catch {
      cancelWrite()
      throw error
    }
  }

  public func detached() throws -> Realm {

    return try Realm(configuration: configuration)
  }
}

public struct RealmWrapper {

  public enum StaticMember {
    public static let writeQueue: DispatchQueue = .init(
      label: "app.muukii.verge.realm_write"
    )
  }

  /// The realm object for the thread that wrapper was created.
  public let realm: Realm

  public init(
    realm: Realm
  ) {
    self.realm = realm
  }

  public init(
    configuration: Realm.Configuration
  ) throws {
    self.realm = try Realm.init(configuration: configuration)
  }

  public func write<Return>(
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ block: @escaping (RealmWrapperTransaction) throws -> Return
  ) throws -> Return {

    realm.beginWrite()
    let transaction = RealmWrapperTransaction(realm: realm)
    let result = try block(transaction)
    try realm.commitWrite()
    return result
  }

  @discardableResult
  public func asyncWrite<Return>(
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ block: @escaping (RealmWrapperTransaction) throws -> Return
  ) -> Future<Return, Error> {

    Future.init { (promise) in
      StaticMember.writeQueue.async {

        do {
          let _realm = try self.realm.detached()
          _realm.beginWrite()
          let transaction = RealmWrapperTransaction(realm: try _realm.detached())
          let result = try block(transaction)
          try _realm.commitWrite()
          promise(.success(result))
        } catch {
          Log.error("Realm error \(error) on \(file) \(function) \(line)")
          promise(.failure(error))
        }
      }
    }

  }

}

public struct RealmWrapperTransaction {

  public let realm: Realm

  init(
    realm: Realm
  ) {
    self.realm = realm
  }

}
