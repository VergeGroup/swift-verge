
extension StoreDriverType {

  public func accumulate<T>(
    queue: MainActorTargetQueue = .mainIsolated(),
    @AccumulationSinkComponentBuilder<Scope> _ buildSubscription: @escaping @MainActor (consuming AccumulationBuilder<Scope>) -> AccumulationSinkGroup<Scope, T>
  ) -> StoreStateSubscription {

    var previous: AccumulationSinkGroup<Scope, T>?

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

public protocol AccumulationSink<Source> {
  associatedtype Source
  consuming func receive(source: borrowing ReadonlyBox<Source>) -> Self
  consuming func receive(other: consuming Self) -> Self
  consuming func consume() -> Self
}

public struct AccumulationBuilder<Source>: ~Copyable {

  public func ifChanged<U: Equatable>(_ selector: @escaping (borrowing Source) -> U) -> AccumulationSinkIfChanged<Source, U> {
    .init(
      selector: selector
    )
  }

}

public struct AccumulationSinkIfChanged<Source, Target: Equatable>: AccumulationSink {

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

  public consuming func receive(source: borrowing ReadonlyBox<Source>) -> Self {

    self.latestValue = selector(source.value)

    return self
  }

  public consuming func receive(other: consuming AccumulationSinkIfChanged<Source, Target>) -> Self {

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

public struct AccumulationSinkGroup<Source, Component>: AccumulationSink {

  private var component: Component
  private var _receiveSource: (ReadonlyBox<Source>, Component) -> Component
  private var _receiveOther: (Component, Component) -> Component
  private var _consume: (Component) -> Component

  init(
    component: Component,
    receiveSource: @escaping (ReadonlyBox<Source>, Component) -> Component,
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

  public consuming func receive(source: ReadonlyBox<Source>) -> Self {
    component = _receiveSource(source, component)
    return self
  }

  public consuming func receive(other: AccumulationSinkGroup<Source, Component>) -> Self {
    component = _receiveOther(other.component, component)
    return self
  }

  public consuming func consume() -> Self {
    component = _consume(component)
    return self
  }

}

@resultBuilder 
public struct AccumulationSinkComponentBuilder<Source> {

  public static func buildBlock() -> AccumulationSinkGroup<Source, Void> {
    return .init()
  }

  public static func buildExpression<S: AccumulationSink>(_ expression: S) -> some AccumulationSink<Source> where S.Source == Source {
    expression
  }
  
  // FIXME: add `where repeat (each S).Source == Source`
  public static func buildBlock<each S: AccumulationSink>(_ sinks: repeat each S) -> AccumulationSinkGroup<Source, (repeat each S)> {

    return AccumulationSinkGroup<Source, (repeat each S)>(
      component: (repeat each sinks),
      receiveSource: { source, component in
        // Waiting https://www.swift.org/blog/pack-iteration/
        func iterate<T: AccumulationSink>(_ left: T) -> T {
          return left.receive(source: source as! ReadonlyBox<T.Source>)
        }

        let modified = (repeat iterate(each component))

        return modified
      },
      receiveOther: { other, current in
        // Waiting https://www.swift.org/blog/pack-iteration/
        func iterate<T: AccumulationSink>(other: consuming T, current: consuming T) -> T {
          return current.receive(other: other)
        }

        let modified = (repeat iterate(other: each other, current: each current))

        return modified
      },
      consume: { component in
        // Waiting https://www.swift.org/blog/pack-iteration/
        func iterate<T: AccumulationSink>(_ component: consuming T) -> T {
          return component.consume()
        }

        let modified = (repeat iterate(each component))

        return modified
      }
    )

  }

}

