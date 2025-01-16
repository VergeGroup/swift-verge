extension EntityType {

  public typealias Derived = Verge.Derived<EntityWrapper<Self>>
  public typealias NonNullDerived = Verge.Derived<NonNullEntityWrapper<Self>>

}

extension Derived where Value: NonNullEntityWrapperType {

  public var entityID: Value.Entity.TypedID {
    self.state.id
  }
}

extension Derived where Value: EntityWrapperType {

  public var entityID: Value.Entity.TypedID? {
    self.state.id
  }

}
