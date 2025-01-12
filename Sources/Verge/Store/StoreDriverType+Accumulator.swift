
extension StoreDriverType {

  /**
   Subscribes states and accumulates into components.
   Against sink method, it does not use Changes object.
   It allows to check if values has changed in the unit of accumulation, not Changes view.
   */
  public func accumulate<T>(
    queue: some MainActorTargetQueueType = .mainIsolated(),
    @AccumulationSinkComponentBuilder<Scope> _ buildSubscription: @escaping @MainActor (consuming AccumulationBuilder<Scope>) -> _AccumulationSinkGroup<Scope, T>
  ) -> StoreStateSubscription {

    var previousBox: ReferenceEdge<_AccumulationSinkGroup<Scope, T>?> = .init(wrappedValue: nil)

    return sinkState(dropsFirst: false, queue: queue) { @MainActor state in

      let builder = AccumulationBuilder<Scope>(previousLoader: {
        previousBox.wrappedValue
      })

      var group = buildSubscription(consume builder)

      // sets the latest value
      group = group.receive(source: state.primitiveBox)

      // sets the previous value
      if let previous = previousBox.wrappedValue {
        group = group.receive(other: previous)
      }

      // runs sink
      group = group.consume()

      previousBox.wrappedValue = group

    }

  }

  /**
   Subscribes states and accumulates into components.
   Against sink method, it does not use Changes object.
   It allows to check if values has changed in the unit of accumulation, not Changes view.
   */
  @_disfavoredOverload
  public func accumulate<T>(
    queue: some TargetQueueType,
    @AccumulationSinkComponentBuilder<Scope> _ buildSubscription: @escaping @Sendable (consuming AccumulationBuilder<Scope>) -> _AccumulationSinkGroup<Scope, T>
  ) -> StoreStateSubscription {

    let previousBox: UnsafeSendableClass<ReferenceEdge<_AccumulationSinkGroup<Scope, T>?>> = .init(
      .init(wrappedValue: nil)
    )
    let lock = VergeConcurrency.UnfairLock()

    return sinkState(dropsFirst: false, queue: queue) { @Sendable state in

      lock.lock()
      defer {
        lock.unlock()
      }

      withUncheckedSendable {

        let builder = AccumulationBuilder<Scope>(previousLoader: {
          previousBox.value.wrappedValue
        })

        var group = buildSubscription(consume builder)

        // sets the latest value
        group = group.receive(source: state.primitiveBox)

        // sets the previous value
        if let previous = previousBox.value.wrappedValue {
          group = group.receive(other: previous)
        }

        // runs sink
        group = group.consume()

        previousBox.value.wrappedValue = group

      }
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

  public var previous: (any AccumulationSink)? {
    previousLoader()
  }

  private let previousLoader: () -> (any AccumulationSink)?

  init(previousLoader: @escaping () -> (any AccumulationSink)?) {
    self.previousLoader = previousLoader
  }

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

  private var counter: Int = 0
  private var countToEmit: Int = 0

  private var handler: ((consuming Target) -> Void)?

  init(
    selector: @escaping (borrowing Source) -> Target
  ) {
    self.selector = selector
  }

  public consuming func dropFirst(_ k: Int = 1) -> Self {
    countToEmit = k
    return self
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
    self.counter = other.counter

    return self
  }

  public consuming func consume() -> Self {

    guard let handler = handler else {
      return self
    }

    if latestValue != previousValue {
      if counter >= countToEmit {
        handler(latestValue!)
      }
      counter += 1
    }

    self.handler = nil

    return self

  }
}

public struct _AccumulationSinkGroup<Source, Component>: AccumulationSink {

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

  public consuming func receive(other: _AccumulationSinkGroup<Source, Component>) -> Self {
    component = _receiveOther(other.component, component)
    return self
  }

  public consuming func consume() -> Self {
    component = _consume(component)
    return self
  }

}

public struct _AccumulationSinkCondition<Source, TrueComponent: AccumulationSink, FalseComponent: AccumulationSink>: AccumulationSink where TrueComponent.Source == Source, FalseComponent.Source == Source {

  private var trueComponent: TrueComponent?
  private var falseComponent: FalseComponent?

  init(
    trueComponent: TrueComponent?,
    falseComponent: FalseComponent?
  ) {
    self.trueComponent = trueComponent
    self.falseComponent = falseComponent
  }

  public consuming func receive(source: ReadonlyBox<Source>) -> Self {
    if let trueComponent = trueComponent {
      self.trueComponent = trueComponent.receive(source: source)
    } else if let falseComponent = falseComponent {
      self.falseComponent = falseComponent.receive(source: source)
    }
    return self
  }

  public consuming func receive(other: _AccumulationSinkCondition<Source, TrueComponent, FalseComponent>) -> Self {
    if let trueComponent = trueComponent, let otherTrueComponent = other.trueComponent {
      self.trueComponent = trueComponent.receive(other: otherTrueComponent)
    } else if let falseComponent = falseComponent, let otherFalseComponent = other.falseComponent {
      self.falseComponent = falseComponent.receive(other: otherFalseComponent)
    }
    return self
  }

  public consuming func consume() -> Self {
    if let trueComponent = trueComponent {
      self.trueComponent = trueComponent.consume()
    } else if let falseComponent = falseComponent {
      self.falseComponent = falseComponent.consume()
    }
    return self
  }

}

struct _AccumulationSinkOptional<Source, Component: AccumulationSink>: AccumulationSink where Component.Source == Source {

  private var component: Component?

  init(
    component: Component?
  ) {
    self.component = component
  }

  consuming func receive(source: ReadonlyBox<Source>) -> Self {
    if let component = component {
      self.component = component.receive(source: source)
    }
    return self
  }

  consuming func receive(other: _AccumulationSinkOptional<Source, Component>) -> Self {
    if let component = component, let otherComponent = other.component {
      self.component = component.receive(other: otherComponent)
    }
    return self
  }

  consuming func consume() -> Self {
    if let component = component {
      self.component = component.consume()
    }
    return self
  }

}

@resultBuilder
public struct AccumulationSinkComponentBuilder<Source> {

  public static func buildExpression<S: AccumulationSink>(_ expression: S) -> S where S.Source == Source {
    expression
  }

  public static func buildBlock() -> some AccumulationSink {
    return _AccumulationSinkGroup<Source, Void>()
  }

  public static func buildEither<TrueComponent: AccumulationSink, FalseComponent: AccumulationSink>(first component: TrueComponent) -> _AccumulationSinkCondition<Source, TrueComponent, FalseComponent> where TrueComponent.Source == Source, FalseComponent.Source == Source {

    return _AccumulationSinkCondition<Source, TrueComponent, FalseComponent>(
      trueComponent: component,
      falseComponent: nil
    )

  }

  public static func buildEither<TrueComponent: AccumulationSink, FalseComponent: AccumulationSink>(second component: FalseComponent) -> _AccumulationSinkCondition<Source, TrueComponent, FalseComponent> where TrueComponent.Source == Source, FalseComponent.Source == Source {

    return _AccumulationSinkCondition<Source, TrueComponent, FalseComponent>(
      trueComponent: nil,
      falseComponent: component
    )
  }

  public static func buildOptional<Component>(_ component: Component?) -> some AccumulationSink where Component : AccumulationSink {
    return _AccumulationSinkOptional.init(component: component)
  }

  // FIXME: add `where repeat (each S).Source == Source`
  public static func buildBlock<each S: AccumulationSink>(_ sinks: repeat each S) -> _AccumulationSinkGroup<Source, (repeat each S)> {

    return _AccumulationSinkGroup<Source, (repeat each S)>(
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

