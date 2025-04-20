import Combine
import Atomics

/**
 A subscription that is compatible with Combine's Cancellable.
 You can manage asynchronous tasks either call the ``cancel()`` to halt the subscription, or allow it to terminate upon instance deallocation, and by implementing the ``storeWhileSourceActive()`` technique, the subscription's active status is maintained until the source store is released.
 */
public final class StoreStateSubscription: StoreSubscriptionBase, @unchecked Sendable {
  
}
