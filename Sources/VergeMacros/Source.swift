
//@freestanding(expression) public macro
// #externalMacro(module: "MacroExamplesPlugin", type: "FontLiteralMacro")

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
@attached(conformance)
public macro DatabaseState() = #externalMacro(module: "VergeMacrosPlugin", type: "DatabaseStateMacro")
