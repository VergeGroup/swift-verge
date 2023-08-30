
@attached(member, names: arbitrary)
//@attached(memberAttribute)
@attached(extension, conformances: NormalizedStorageType, Equatable, names: named(Context), named(BBB), arbitrary)
public macro NormalizedStorage() = #externalMacro(module: "VergeMacrosPlugin", type: "DatabaseMacro")

@attached(accessor)
public macro TableAccessor() = #externalMacro(module: "VergeMacrosPlugin", type: "DatabaseTableMacro")


#if DEBUG

struct A: EntityType {
  typealias EntityIDRawType = String
  var entityID: EntityID {
    .init("")
  }
}

@NormalizedStorage
struct MyDatabase {
  @TableAccessor
  var user: Table<A>
}

private func play() {

  var db = MyDatabase.init()

  db.performBatchUpdates { t in
    t.modifying.user.insert(.init())
  }

//  db.user = .init(identifier: "")
}
//#Database(tables: Table<A>(), Table<A>())

#endif
