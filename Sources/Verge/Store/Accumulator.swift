
public protocol Sink<Source> {
  associatedtype Source
  func receive(source: Source)
}

public struct AccumulationBuilder<Source>: ~Copyable {

  public func ifChanged<U: Equatable>(_ selector: @escaping (Source) -> U) -> SinkIfChanged<Source, U> {
    .init(selector: selector)
  }

}

public final class SinkIfChanged<Source, Target: Equatable>: Sink {

  private let selector: (Source) -> Target

  private var latestValue: Target?
  private var handler: ((consuming Target) -> Void)?

  public init(selector: @escaping (Source) -> Target) {
    self.selector = selector
  }

  public func `do`(_ perform: @escaping (consuming Target) -> Void) -> Self {
    self.handler = perform
    return self
  }

  public func receive(source: Source) {

    let selected = selector(source)

    guard latestValue != selected else {
      return
    }

    latestValue = selected

    handler?(selected)

  }
}

extension DispatcherType {

  public func accumulate(
    queue: MainActorTargetQueue = .mainIsolated(),
    @SinkComponentBuilder<Scope> _ buildSubscription: (consuming AccumulationBuilder<Scope>) -> SinkGroup<Scope>) -> Cancellable {

    let builder = AccumulationBuilder<Scope>()
    let group = buildSubscription(consume builder)

    return sinkState(dropsFirst: false, queue: queue) { state in

      group.receive(source: state.primitive)

    }

  }

}

public struct SinkBox<Source>: Sink {

  private let base: any Sink<Source>

  public init(base: some Sink<Source>) {
    self.base = base
  }

  public func receive(source: Source) {
    base.receive(source: source)
  }
}

public struct SinkGroup<Source>: Sink {

  private let _receive: (Source) -> Void

  init(receive: @escaping (Source) -> Void) {
    self._receive = receive
  }

  public func receive(source: Source) {
    self._receive(source)
  }
}

@resultBuilder 
public struct SinkComponentBuilder<Source> {

  public static func buildBlock() -> SinkGroup<Source> {
    return .init(receive: { _ in })
  }
//
//  public static func buildBlock<each Target>(_ components: repeat AccumulationBuilder<Source>.IfChangedSink<each Target>) -> SinkGroup<Source> {
//    .init { source in
//
//      func run<T>(_ component: AccumulationBuilder<Source>.IfChangedSink<T>) {
//        component.receive(source: source)
//      }
//
//      repeat run(each components)
//
//    }
//  }

  public static func buildExpression(_ expression: any Sink<Source>) -> SinkBox<Source> {
    .init(base: expression)
  }

  public static func buildBlock(_ sinks: (SinkBox<Source>)...) -> SinkGroup<Source> {
    .init { source in

      for sink in sinks {
        sink.receive(source: source)
      }

    }
  }

}
