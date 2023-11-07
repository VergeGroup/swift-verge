import VergeNormalization

public protocol NoromalizedStoragePathType<Store, _StorageSelector> {
  associatedtype Store: DerivedMaking & AnyObject
  associatedtype _StorageSelector: StorageSelector
}

public protocol NormalizedStorageDerivingType: NormalizedStorageType {
  associatedtype NormalizedStoragePath: NoromalizedStoragePathType
}

@attached(
  extension,
  conformances: NormalizedStorageType,
  NormalizedStorageDerivingType,
  Sendable,
  Equatable,
  names: arbitrary
)
public macro NormalizedStorageDeriving() =
  #externalMacro(module: "VergeMacrosPlugin", type: "NormalizedStorageDerivingMacro")

#if DEBUG

struct A: EntityType {
  typealias EntityIDRawType = String
  var entityID: EntityID {
    .init("")
  }
}

@NormalizedStorageDeriving
struct MyDatabase {
  @Table
  var user: Tables.Hash<A>

  @Table
  var user2: Tables.Hash<A> = .init()

  @Table
  var user3: Tables.Hash<A> = .init()

  @Table
  var user4: Tables.Hash<A> = .init()
}

private func play() {

  var db = MyDatabase.init(user: .init())

  db.performBatchUpdates { t in
    t.modifying.user.insert(.init())
  }

  //  db.user = .init(identifier: "")
}
//#Database(tables: Table<A>(), Table<A>())

#endif
