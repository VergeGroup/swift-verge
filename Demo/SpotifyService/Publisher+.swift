
import Combine

extension Publisher {

  @discardableResult
  func start() -> Future<Output, Failure> {
    return .init { promise in

      var cancellableRef: Unmanaged<AnyCancellable>? = nil

      let c = self.sink(receiveCompletion: { (completion) in
        switch completion {
        case .failure(let error):
          promise(.failure(error))
          cancellableRef?.release()
        case .finished:
          break
        }
      }) { (value) in
        promise(.success(value))
        cancellableRef?.release()
      }

      cancellableRef = Unmanaged.passRetained(c)
    }
  }
}
