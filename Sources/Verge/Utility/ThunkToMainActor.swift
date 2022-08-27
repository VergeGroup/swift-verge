import Foundation

@preconcurrency
@MainActor
@inline(__always)
func thunkToMainActor(_ run: @MainActor () throws -> Void) rethrows {
  assert(Thread.isMainThread)
  try run()
}

@preconcurrency
@MainActor
@inline(__always)
func thunkToMainActor(_ run: @MainActor () -> Void) {
  assert(Thread.isMainThread)
  run()
}
