
/// same as DispatcherType
public protocol AsyncStoreContextType {
  associatedtype WrappedStore: AsyncStoreType
  associatedtype Scope = WrappedStore.State

  var store: WrappedStore { get }
  var scope: WritableKeyPath<WrappedStore.State, Scope> { get }
}
