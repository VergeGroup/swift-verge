import SwiftUI

extension View {

  /// Adds an action to perform when the specified `DispatcherType` publishes a state change.
  ///
  /// Use `onReceiveState(_ instance: perform:)` to perform an action when a `DispatcherType` instance publishes a state change.
  /// The system calls the `perform` closure on the main thread each time the `State` changes.
  ///
  ///     struct MyView: View {
  ///
  ///      let viewModel: MyViewModel
  ///
  ///      var body: some View {
  ///        Text("Hello, World!")
  ///          .onReceiveState(viewModel) { state in
  ///            // Handle state changes here
  ///          }
  ///      }
  ///     }
  ///
  /// - Parameters:
  ///   - instance: The `DispatcherType` instance to subscribe to.
  ///   - perform: A closure to execute when the `State` changes.
  public func onReceiveState<D: StoreDriverType>(_ instance: D, perform: @escaping @MainActor (Changes<D.TargetStore.State>) -> Void) -> some View {
    onReceive(instance.store.asStore()._statePublisher().receive(on: DispatchQueue.main), perform: perform)
  }

  /// Adds an action to perform when the specified `DispatcherType` publishes an activity.
  ///
  /// Use `onReceiveActivity(_ instance: perform:)` to perform an action when a `DispatcherType` instance publishes an activity.
  /// The system calls the `perform` closure on the main thread each time the `Activity` is published.
  ///
  ///     struct MyView: View {
  ///
  ///      let viewModel: MyViewModel
  ///
  ///      var body: some View {
  ///        Text("Hello, World!")
  ///          .onReceiveActivity(viewModel) { activity in
  ///            // Handle activities here
  ///          }
  ///      }
  ///     }
  ///
  /// - Parameters:
  ///   - instance: The `DispatcherType` instance to subscribe to.
  ///   - perform: A closure to execute when the `Activity` is published.
  public func onReceiveActivity<D: StoreDriverType>(_ instance: D, perform: @escaping @MainActor (D.TargetStore.Activity) -> Void) -> some View {
    onReceive(instance.store.asStore()._activityPublisher().receive(on: DispatchQueue.main), perform: perform)
  }

}
