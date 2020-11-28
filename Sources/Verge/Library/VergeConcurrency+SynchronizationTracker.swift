//
// Copyright (c) 2020 muukii
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

extension VergeConcurrency {
  /// imported RxSwift
  public final class SynchronizationTracker {
    private let _lock = NSRecursiveLock()
    
    private var _threads = [UnsafeMutableRawPointer: Int]()
    
    private func synchronizationError(_ message: String) {
      print(message)
    }
    
    public init() {}
    
    public func register() {
      self._lock.lock(); defer { self._lock.unlock() }
      let pointer = Unmanaged.passUnretained(Thread.current).toOpaque()
      let count = (self._threads[pointer] ?? 0) + 1
      
      if count > 1 {
        self.synchronizationError("Reentrancy anomaly was detected")
      }
      
      self._threads[pointer] = count
      
      if self._threads.count > 1 {
        self.synchronizationError("Synchronization anomaly was detected")
      }
    }
    
    public func unregister() {
      self._lock.lock(); defer { self._lock.unlock() }
      let pointer = Unmanaged.passUnretained(Thread.current).toOpaque()
      self._threads[pointer] = (self._threads[pointer] ?? 1) - 1
      if self._threads[pointer] == 0 {
        self._threads[pointer] = nil
      }
    }
  }
}
