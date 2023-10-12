
import HashTreeCollections

public enum Indexes {

  /// A Indexing store
  ///
  /// {
  ///   Grouping-ID : [
  ///     - Grouped-ID
  ///     - Grouped-ID
  ///     - Grouped-ID
  ///   ],
  ///   Grouping-ID : [
  ///     - Grouped-ID
  ///     - Grouped-ID
  ///     - Grouped-ID
  ///   ]
  /// }
  ///
//  public typealias GroupByEntity = Never

//  public typealias GroupByKey = Never

  /**
   Mapping another key to the entity id.
   ```
   [
     Key: EntityID
     Key: EntityID
     Key: EntityID
   ]
   ```
   */
  public typealias Hash<Key: Hashable, Entity: EntityType> = HashTreeCollections.TreeDictionary<Key, Entity.EntityID>

  public typealias Ordered<Entity: EntityType> = Array<Entity.EntityID>

  public typealias Set = Never

}
