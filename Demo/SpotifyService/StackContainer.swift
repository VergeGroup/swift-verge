
import Foundation

import Combine
import VergeStore
import CombineExt
import Moya

public enum BackendError: Swift.Error {
  case unknown
}

public final class BackendStack: ObservableObject, Equatable {
  
  public static func == (lhs: BackendStack, rhs: BackendStack) -> Bool {
    lhs === rhs
  }

  public enum Stack {
    case loggedIn(LoggedInStack)
    case loggedOut(LoggedOutStack)
  }
  
  @Published public private(set) var stack: Stack
  
  private var subscriptions = Set<AnyCancellable>()
  public let store: BackendStore
  public let externalDataSource: ExternalDataSource
  public var bag = Set<VergeAnyCancellable>()
  
  public init(identifier: String) {

    self.externalDataSource = .init(identifier: identifier)

    let _store = BackendStore.init(initialState: .init(), logger: DefaultStoreLogger.shared)
    self.store = _store

    let session = try! externalDataSource
      .makeUserDataRealm()
      .object(ofType: RealmObjects.Session.self)

    syncSession: do {

      /**
       Here is an example that uses Realm in Verge
       */

      _store.commit {
        $0.session = session.freeze()
      }

      let token = session.observe { (change: ObjectChange<RealmObjects.Session>) in
        switch change {
        case .error(let error):
          Log.error(error)
        case .change(let object, _):
          _store.commit {
            $0.session = object.freeze()
          }
        case .deleted:
          break
        }
      }

      VergeAnyCancellable {
        token.invalidate()
      }
      .store(in: &bag)

    }

    let token = session.authAccessToken

    switch token {
    case .none:
      self.stack = .loggedOut(.init(store: store))
    case .some:
      store.commit {
        $0.loggedIn = .init()
      }
      self.stack = .loggedIn(.init(
        externalDataSource: externalDataSource,
        store: store
        )
      )
    }

  }

  @discardableResult
  public func receiveAuthCode(_ code: Auth.AuthCode) -> Future<Void, Error> {
    
    guard case .loggedOut(let loggedOutStack) = stack else {
      return .failure(BackendError.unknown)
    }

    loggedOutStack.service.commit {
      $0.isLoginProcessing = true
    }

    return loggedOutStack.service.fetchToken(code: code)
      .map { auth -> LoggedInStack in

        let realmWrapper = self.externalDataSource.makeUserDataRealm()

        do {
          let session = try realmWrapper.write { (transaction) -> RealmObjects.Session in
            let session = try transaction.object(ofType: RealmObjects.Session.self)
            session.update(with: auth)
            transaction.realm.add(session, update: .all)
            return session
          }

          self.store.commit {
            $0.session = session.freeze()
            $0.loggedIn = .init()
          }
        } catch {
          assertionFailure()
          Log.error("\(error)")
        }

        let loggedInStack = LoggedInStack(
          externalDataSource: self.externalDataSource,
          store: self.store
        )

        return loggedInStack
    }
    .mapError { $0 as Error }
    .flatMap { stack in
      stack.service.fetchMe()
        .mapError { $0 as Error }
        .map { _ in stack }
    }
    .handleEvents(
      receiveOutput: { stack in
        self.stack = .loggedIn(stack)
    }, receiveCompletion: { comp in
      loggedOutStack.service.commit {
        $0.isLoginProcessing = false
      }
    })
      .map { _ in }
      .start()

  }
}

import RealmSwift

public final class ExternalDataSource {

  private static let realmSchemaVersion: UInt64 = {

    let versions: [UInt64] = [
      101,
    ]

    return versions.last!
  }()

  private static var rootDirectoryPath: String {
    let root = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
    return (root as NSString).appendingPathComponent(Bundle.main.bundleIdentifier!)
  }

  private let workingDirectory: String

  init(identifier: String) {

    self.workingDirectory = Self.rootDirectoryPath + "/\(identifier)"

    makeDirectory: do {
      try FileManager.default.createDirectory(atPath: workingDirectory, withIntermediateDirectories: true, attributes: [:])
    } catch {
      fatalError("Failed to create directory Path: \(workingDirectory)")
    }

    let wrapper = makeUserDataRealm()

    try! wrapper.write { (realm) in
      let session = try realm.object(ofType: RealmObjects.Session.self)
      print(session)
    }

  }

  func makeUserDataRealm() -> RealmWrapper {

    let configuration = RealmSwift.Realm.Configuration(
      fileURL: URL(fileURLWithPath: workingDirectory + "/user_data.realm"),
      inMemoryIdentifier: nil,
      encryptionKey: nil,
      readOnly: false,
      schemaVersion: Self.realmSchemaVersion,
      migrationBlock: { (migration, oldSchemaVersion) -> Void in

    },
      objectTypes: [
        RealmObjects.Session.self
    ])

    let wrapper = try! RealmWrapper(configuration: configuration)
    return wrapper
  }
}

public protocol SingleRecordType where Self: RealmSwift.Object  {
  var uniqueID: String { get }
  static var uniqueIDValue: String { get }
}

extension SingleRecordType {
  public static var uniqueIDValue: String {
    return String(reflecting: Self.self)
  }
}

enum SingleRecordError : Error {
  case failedToDetach
}

extension RealmWrapper {

  func object<SingleRecord: SingleRecordType>(ofType type: SingleRecord.Type) throws -> SingleRecord {
    if let object = realm.object(ofType: SingleRecord.self, forPrimaryKey: SingleRecord.uniqueIDValue) {
      return object
    }
    return try write {
      try $0.object(ofType: SingleRecord.self)
    }
  }

}

extension RealmWrapperTransaction {

  func object<SingleRecord: SingleRecordType>(ofType type: SingleRecord.Type) throws -> SingleRecord {
    try SingleRecord.fetchOrCreate(on: self.realm)
  }

}

extension SingleRecordType {

  fileprivate static func fetchOrCreate(on realm: Realm) throws -> Self {

    func create(_ realm: Realm) throws -> Self {
      let object = self.init()
      realm.add(object, update: .error)
      return object
    }

    if let object = realm.object(ofType: self, forPrimaryKey: Self.uniqueIDValue) {
      return object
    }
    return try create(realm)
  }

}
