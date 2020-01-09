//
//  RxGetter.swift
//  VergeGetterRx
//
//  Created by muukii on 2020/01/09.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import RxSwift

#if !COCOAPODS
import VergeStore
import VergeCore
#endif

public class RxGetter<Output>: _Getter<Output>, ObservableType {
  
  public typealias Element = Output
  
  let output: BehaviorSubject<Output>
  
  private let disposeBag = DisposeBag()
  
  public override var value: Output {
    try! output.value()
  }
  
  public convenience init<O: ObservableConvertibleType>(from observable: () -> O) where O.Element == Output {
    self.init(from: observable())
  }
  
  public init<O: ObservableConvertibleType>(from observable: O) where O.Element == Output {
    
    let pipe = observable.asObservable().share(replay: 1, scope: .forever)
    
    var initialValue: Output!
    
    _ = pipe.debug().take(1).subscribe(onNext: { value in
      initialValue = value
    })
    
    precondition(initialValue != nil, "\(observable) can't use scheduler")
    
    self.output = BehaviorSubject<Output>(value: initialValue)
    
    pipe.subscribe(self.output).disposed(by: disposeBag)
    
  }
    
  init(output: BehaviorSubject<Output>) {
    self.output = output
  }
  
  public func subscribe<Observer>(_ observer: Observer) -> Disposable where Observer : ObserverType, Element == Observer.Element {
    output.subscribe(observer)   
  }
        
}

public final class RxGetterSource<Input, Output>: RxGetter<Output> {
      
  private let disposeBag = DisposeBag()
  
  init(
    input: Observable<Output>
  ) {
        
    super.init(from: input)
            
  }
  
  public func asGetter() -> RxGetter<Output> {
    self
  }
  
}

extension Storage: ReactiveCompatible {}
extension StoreBase: ReactiveCompatible {}

extension Reactive where Base : RxValueContainerType {
  
  public func getter<Output>(
    filter: EqualityComputer<Base.Value>,
    map: @escaping (Base.Value) -> Output
  ) -> RxGetterSource<Base.Value, Output> {
    
    let pipe = base.asObservable()
      .distinctUntilChanged(filter)
      .map(map)
    
    let getter = RxGetterSource<Base.Value, Output>.init(input: pipe)
    
    return getter
    
  }
  
}

#if !COCOAPODS
import VergeORM
#endif

fileprivate final class _GetterCache {
  
  private let cache = NSCache<NSString, AnyObject>()
  
  @inline(__always)
  private func key<E: EntityType>(entityID: E.EntityID) -> NSString {
    "\(ObjectIdentifier(E.self))_\(entityID)" as NSString
  }
  
  func getter<E: EntityType>(entityID: E.EntityID) -> AnyObject? {
    cache.object(forKey: key(entityID: entityID))
  }
  
  func setGetter<E: EntityType>(_ getter: AnyObject, entityID: E.EntityID) {
    cache.setObject(getter, forKey: key(entityID: entityID))
  }
  
}

fileprivate var _valueContainerAssociated: Void?

extension Reactive where Base : RxValueContainerType, Base.Value : DatabaseEmbedding {
  
  private var cache: _GetterCache {
    
    if let associated = objc_getAssociatedObject(base, &_valueContainerAssociated) as? _GetterCache {
      
      return associated
      
    } else {
      
      let associated = _GetterCache()
      objc_setAssociatedObject(base, &_valueContainerAssociated, associated, .OBJC_ASSOCIATION_RETAIN)
      return associated
    }
  }
    
  /// Make getter to select value with update closure
  ///
  /// - Parameters:
  ///   - update: Updating output value each Input value updated.
  ///   - additionalEqualityComputer: Check to necessory of needs to update to reduce number of updating.
  public func makeEntityGetter<Output>(
    update: @escaping (Base.Value.Database) -> Output,
    additionalEqualityComputer: EqualityComputer<Base.Value.Database>?
  ) -> RxGetterSource<Base.Value, Output> {
    
    let path = Base.Value.getterToDatabase
    
    let checkDatabaseUpdated = EqualityComputer<Base.Value.Database>.init(
      selector: { input -> (Date, Date) in
        let v = input
        return (v._backingStorage.entityUpdatedAt, v._backingStorage.indexUpdatedAt)
    },
      equals: { (old, new) -> Bool in
        old == new
    })
    
    let computer = EqualityComputer.init(or: [
      checkDatabaseUpdated,
      additionalEqualityComputer
      ].compactMap { $0 })
    
    let _getter = getter(
      filter: EqualityComputer.init(selector: { path($0) }, equals: { (old, new) -> Bool in
        computer.isEqual(value: new)
      }),
      map: { (value) -> Output in
        let t = SignpostTransaction("ORM.Getter.update")
        defer {
          t.end()
        }
        return update(Base.Value.getterToDatabase(value))
    })
    
    return _getter
  }
  
  public func makeEntityGetter<E: EntityType>(
    from entityID: E.EntityID,
    additionalEqualityComputer: EqualityComputer<Base.Value.Database>?
  ) -> RxGetterSource<Base.Value, E?> {
    
    let newGetter = makeEntityGetter(
      update: { db in
        db.entities.table(E.self).find(by: entityID)
    },
      additionalEqualityComputer: .init(or: [
        .tableEqual(E.self),
        additionalEqualityComputer
        ].compactMap { $0 }
      )
    )
    return newGetter
    
  }
  
  public func makeNonNullEntityGetter<E: EntityType>(
    from entity: E,
    additionalEqualityComputer: EqualityComputer<Base.Value.Database>?
  ) -> RxGetterSource<Base.Value, E> {
    
    var box = entity
    let entityID = entity.entityID
    
    let newGetter = makeEntityGetter(
      update: { db -> E in
        let table = db.entities.table(E.self)
        if let e = table.find(by: entityID) {
          box = e
        }
        return box
    },
      additionalEqualityComputer: .init(or: [
        .tableEqual(E.self),
        additionalEqualityComputer
        ].compactMap { $0 }
      )
    )
    return newGetter
    
  }
  
  // MARK: -
  
  /// A entity getter that entity id based.
  /// - Parameters:
  ///   - tableSelector:
  ///   - entityID:
  public func entityGetter<E: EntityType>(from entityID: E.EntityID) -> RxGetterSource<Base.Value, E?> {
    
    let _cache = cache
    
    guard let getter = _cache.getter(entityID: entityID) as? RxGetterSource<Base.Value, E?> else {
      let newGetter = makeEntityGetter(from: entityID, additionalEqualityComputer: nil)
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getter
    
  }
  
  public func entityGetter<E: EntityType & Equatable>(
    from entityID: E.EntityID
  ) -> RxGetterSource<Base.Value, E?> {
    
    let _cache = cache
    
    guard let getter = _cache.getter(entityID: entityID) as? RxGetterSource<Base.Value, E?> else {
      let newGetter = makeEntityGetter(from: entityID, additionalEqualityComputer: .entityEqual(entityID))
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getter
    
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType>(from entity: E) -> RxGetterSource<Base.Value, E> {
    
    let _cache = cache
    
    guard let getter = _cache.getter(entityID: entity.entityID) as? RxGetterSource<Base.Value, E> else {
      let entityID = entity.entityID
      let newGetter = makeNonNullEntityGetter(from: entity, additionalEqualityComputer: nil)
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getter
    
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    from entity: E
  ) -> RxGetterSource<Base.Value, E> {
    
    let _cache = cache
    
    guard let getter = _cache.getter(entityID: entity.entityID) as? RxGetterSource<Base.Value, E> else {
      let entityID = entity.entityID
      let newGetter = makeNonNullEntityGetter(from: entity, additionalEqualityComputer: .entityEqual(entityID))
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getter
    
  }
  
  // MARK: -
  
  /// A selector that if get nil then return latest non-null value
  @inline(__always)
  public func nonNullEntityGetters<S: Sequence, E: EntityType>(
    from entities: S
  ) -> [RxGetterSource<Base.Value, E>] where S.Element == E {
    entities.map {
      nonNullEntityGetter(from: $0)
    }
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    from entityID: E.EntityID
  ) -> RxGetterSource<Base.Value, E>? {
            
    let db = Base.Value.getterToDatabase(base.wrappedValue)
    guard let entity = db.entities.table(E.self).find(by: entityID) else { return nil }
    return nonNullEntityGetter(from: entity)
  }
  
  @inline(__always)
  public func nonNullEntityGetters<S: Sequence, E: EntityType>(
    from entityIDs: S
  ) -> [E.EntityID : RxGetterSource<Base.Value, E>] where S.Element == E.EntityID {
        
    let db = Base.Value.getterToDatabase(base.wrappedValue)
    
    return db.entities.table(E.self).find(in: entityIDs)
      .reduce(into: [E.EntityID : RxGetterSource<Base.Value, E>](), { (container, entity) in
        container[entity.entityID] = nonNullEntityGetter(from: entity)
      })
  }
  
  /// A selector that if get nil then return latest non-null value
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType>(
    from insertionResult: EntityTable<Base.Value.Database.Schema, E>.InsertionResult
  ) -> RxGetterSource<Base.Value, E> {
    
    return nonNullEntityGetter(from: insertionResult.entity)
    
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    from insertionResult: EntityTable<Base.Value.Database.Schema, E>.InsertionResult
  ) -> RxGetterSource<Base.Value, E> {
    
    return nonNullEntityGetter(from: insertionResult.entity)
  }
  
  public func nonNullEntityGetters<E: EntityType, S: Sequence>(
    from insertionResults: S
  ) -> [RxGetterSource<Base.Value, E>] where S.Element == EntityTable<Base.Value.Database.Schema, E>.InsertionResult {
    insertionResults.map {
      nonNullEntityGetter(from: $0)
    }
  }
  
  public func nonNullEntityGetters<E: EntityType & Equatable, S: Sequence>(
    from insertionResults: S
  ) -> [RxGetterSource<Base.Value, E>] where S.Element == EntityTable<Base.Value.Database.Schema, E>.InsertionResult {
    insertionResults.map {
      nonNullEntityGetter(from: $0)
    }
  }
  
}
