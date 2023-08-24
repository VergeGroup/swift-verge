/**
 struct Database: DatabaseType {

 struct Schema: EntitySchemaType {
 let author = Author.EntityTableKey()
 }

 struct Indexes: IndexesType {
 let allBooks = HashIndex<Schema, String, Author>.Key()
 }

 var _backingStorage: BackingStorage = .init()
 }
 */

@attached(member, names: named(_backingStorage))
@attached(extension, conformances: DatabaseType)
public macro DatabaseState() = #externalMacro(module: "VergeMacrosPlugin", type: "DatabaseStateMacro")
