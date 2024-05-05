
public protocol Sink<Source> {
  associatedtype Source
  consuming func receive(source: borrowing ReadingBox<Source>) -> Self
  consuming func receive(other: consuming Self) -> Self
  consuming func consume() -> Self
}

public struct AccumulationBuilder<Source>: ~Copyable {

  public func ifChanged<U: Equatable>(_ selector: @escaping (borrowing Source) -> U) -> SinkIfChanged<Source, U> {
    .init(
      selector: selector
    )
  }

}

public struct SinkIfChanged<Source, Target: Equatable>: Sink {

  private let selector: (borrowing Source) -> Target

  private var latestValue: Target?
  private var previousValue: Target?

  private var handler: ((consuming Target) -> Void)?

  init(
    selector: @escaping (borrowing Source) -> Target
  ) {
    self.selector = selector
  }

  /**
   the closure will be released after consumed.
   */
  public consuming func `do`(@_inheritActorContext @_implicitSelfCapture _ perform: @escaping (consuming Target) -> Void) -> Self {
    self.handler = perform
    return self
  }

  public consuming func receive(source: borrowing ReadingBox<Source>) -> Self {

    self.latestValue = selector(source.value)

    return self
  }

  public consuming func receive(other: consuming SinkIfChanged<Source, Target>) -> Self {

    self.previousValue = other.latestValue

    return self
  }

  public consuming func consume() -> Self {

    guard let handler = handler else {
      return self
    }

    if latestValue != previousValue {
      handler(latestValue!)
    }

    self.handler = nil

    return self

  }
}

extension StoreDriverType {

  public func accumulate<T>(
    queue: MainActorTargetQueue = .mainIsolated(),
    @SinkComponentBuilder<Scope> _ buildSubscription: @escaping @MainActor (consuming AccumulationBuilder<Scope>) -> SinkGroup<Scope, T>
  ) -> StoreStateSubscription {

    var previous: SinkGroup<Scope, T>?

    return sinkState(dropsFirst: false, queue: queue) { state in

      let builder = AccumulationBuilder<Scope>()

      var group = buildSubscription(consume builder)

      // sets the latest value
      group = group.receive(source: state.primitiveBox)

      // sets the previous value
      if let previous {
        group = group.receive(other: previous)
      }

      // runs sink
      group = group.consume()

      previous = group

    }

  }

}

public struct SinkGroup<Source, Component>: Sink {

  private var component: Component
  private var _receiveSource: (ReadingBox<Source>, Component) -> Component
  private var _receiveOther: (Component, Component) -> Component
  private var _consume: (Component) -> Component

  init(
    component: Component,
    receiveSource: @escaping (ReadingBox<Source>, Component) -> Component,
    receiveOther: @escaping (Component, Component) -> Component,
    consume: @escaping (Component) -> Component
  ) {
    self.component = component
    self._receiveSource = receiveSource
    self._receiveOther = receiveOther
    self._consume = consume
  }

  init() where Component == Void {
    self.component = ()
    self._receiveSource = { _, component in component }
    self._receiveOther = { _, component in component }
    self._consume = { component in component }
  }

  public consuming func receive(source: ReadingBox<Source>) -> Self {
    component = _receiveSource(source, component)
    return self
  }

  public consuming func receive(other: SinkGroup<Source, Component>) -> Self {
    component = _receiveOther(other.component, component)
    return self
  }

  public consuming func consume() -> Self {
    component = _consume(component)
    return self
  }

}

@resultBuilder 
public struct SinkComponentBuilder<Source> {

  public static func buildBlock() -> SinkGroup<Source, Void> {
    return .init()
  }

  public static func buildExpression<S: Sink>(_ expression: S) -> some Sink<Source> where S.Source == Source {
    expression
  }
  
  // FIXME: add `where repeat (each S).Source == Source`
  public static func buildBlock<each S: Sink>(_ sinks: repeat each S) -> SinkGroup<Source, (repeat each S)> {

    return SinkGroup<Source, (repeat each S)>(
      component: (repeat each sinks),
      receiveSource: { source, component in
        func iterate<T: Sink>(_ left: T) -> T {
          return left.receive(source: source as! ReadingBox<T.Source>)
        }

        let modified = (repeat iterate(each component))

        return modified
      },
      receiveOther: { other, current in
        func iterate<T: Sink>(other: consuming T, current: consuming T) -> T {
          return current.receive(other: other)
        }

        let modified = (repeat iterate(other: each other, current: each current))

        return modified
      },
      consume: { component in
        func iterate<T: Sink>(_ component: consuming T) -> T {
          return component.consume()
        }

        let modified = (repeat iterate(each component))

        return modified
      }
    )

  }

}

