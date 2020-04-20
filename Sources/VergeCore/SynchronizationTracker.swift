//
//  SynchronizationTracker.swift
//  VergeCore
//
//  Created by muukii on 2020/04/21.
//  Copyright © 2020 muukii. All rights reserved.
//

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
