
//@attached(member, names: arbitrary)
//@attached(memberAttribute)
@attached(extension, conformances: NormalizedStorageType, Equatable, names: named(Context), named(BBB), arbitrary)
public macro NormalizedStorage() = #externalMacro(module: "VergeMacrosPlugin", type: "NormalizedStorageMacro")

@attached(peer)
public macro Table() = #externalMacro(module: "VergeMacrosPlugin", type: "TableMacro")

@attached(peer)
public macro Index() = #externalMacro(module: "VergeMacrosPlugin", type: "DatabaseIndexMacro")

#if DEBUG

struct A: EntityType {
  typealias EntityIDRawType = String
  var entityID: EntityID {
    .init("")
  }
}

@NormalizedStorage
struct MyDatabase {
  @Table
  var user: Tables.Hash<A>

  @Table
  var user2: Tables.Hash<A> = .init()

  @Table
  var user3: Tables.Hash<A> = .init()
}

extension MyDatabase {

  static func c(lhs: Self, rhs: Self) -> Bool {

    lhs.user.updatedMarker == rhs.user.updatedMarker

  }

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
