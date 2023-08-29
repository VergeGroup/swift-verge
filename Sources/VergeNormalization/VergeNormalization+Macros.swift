
@attached(member, names: arbitrary)
@attached(memberAttribute)
@attached(extension, conformances: NormalizedStorageType, Equatable, names: named(Context), named(BBB))
public macro Database() = #externalMacro(module: "VergeMacrosPlugin", type: "DatabaseMacro")

@attached(accessor)
public macro Table() = #externalMacro(module: "VergeMacrosPlugin", type: "DatabaseTableMacro")

#if DEBUG

struct A: EntityType {
  typealias EntityIDRawType = String
  var entityID: EntityID {
    .init("")
  }
}

@Database
struct MyDatabase {
  var user: Table<A>
}

private func play() {

  var db = MyDatabase(_$user: .init(identifier: ""))

  db.performBatchUpdates { t in
    t.modifying.user.insert(.init())
  }

//  db.user = .init(identifier: "")
}
//#Database(tables: Table<A>(), Table<A>())

#endif
