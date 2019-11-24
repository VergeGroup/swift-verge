
import Foundation

import RxCocoa

extension VergeType {
  
  public func commitBinder<S>(
    name: String = "",
    description: String = "",
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line,
    mutate: @escaping (inout State, S) -> Void
    ) -> Binder<S> {
    
    return Binder<S>(self) { t, e in
      t.commit(name, description, file, function, line) { s in
        mutate(&s, e)
      }
    }
  }
  
  public func commitBinder<S>(
    name: String = "",
    description: String = "",
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line,
    mutate: @escaping (inout State, S?) -> Void
    ) -> Binder<S?> {
    
    return Binder<S?>(self) { t, e in
      t.commit(name, description, file, function, line) { s in
        mutate(&s, e)
      }
    }
  }
  
  public func commitBinder<S>(
    name: String = "",
    description: String = "",
    target: WritableKeyPath<State, S>,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
    ) -> Binder<S> {
    
    return Binder<S>(self) { t, e in
      t.commit(name, description, file, function, line) { s in
        s[keyPath: target] = e
      }
    }
  }
  
  public func commitBinder<S>(
    name: String = "",
    description: String = "",
    target: WritableKeyPath<State, S?>,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
    ) -> Binder<S?> {
    
    return Binder<S?>(self) { t, e in
      t.commit(name, description, file, function, line) { s in
        s[keyPath: target] = e
      }
    }
  }
}
