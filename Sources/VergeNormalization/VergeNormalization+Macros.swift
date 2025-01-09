
//@attached(member, names: arbitrary)
//@attached(memberAttribute)
@attached(extension, conformances: NormalizedStorageType, Equatable, Sendable, names: named(Context), named(BBB), arbitrary)
public macro NormalizedStorage() = #externalMacro(module: "VergeMacrosPlugin", type: "NormalizedStorageMacro")

@attached(peer)
public macro Table() = #externalMacro(module: "VergeMacrosPlugin", type: "TableMacro")

@attached(peer)
public macro Index() = #externalMacro(module: "VergeMacrosPlugin", type: "IndexMacro")

#if DEBUG

struct A: EntityType {
  typealias TypedIdentifierRawValue = String
  var typedID: TypedID {
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
