
import Foundation
import Moya
import Combine

final class RefreshTokenProvider<Target: TargetType> {

  private let innerProvider: MoyaProvider<Target>
  private let tokenController: TokenController<AuthResponse>

  init(tokenController: TokenController<AuthResponse>) {
    self.innerProvider = .init(plugins: [
      AccessTokenPlugin { _ in tokenController.current!.accessToken }
    ])
    self.tokenController = tokenController
  }

  func requestPublisher(_ target: Target) -> AnyPublisher<Response, Error> {

    let request = AnyPublisher<Response, MoyaError>.init { (s) in
      let cancellable = self.innerProvider.request(target) { (result) in
        switch result {
        case .success(let response):
          do {
            let response = try response.filterSuccessfulStatusAndRedirectCodes()
            s.send(response)
          } catch let error as MoyaError {
            s.send(completion: .failure(error))
          } catch {
            assertionFailure()
          }
        case .failure(let error):
          s.send(completion: .failure(error))
        }
      }
      return AnyCancellable {
        cancellable.cancel()
      }
    }

    return tokenController.validate()
      .setFailureType(to: Error.self)
      .flatMap { [tokenController = tokenController] _ in
        request.catch { (error: MoyaError) -> AnyPublisher<Response, Error> in
          guard case .statusCode(let response) = error else {
            return Fail(error: error).mapError { $0 }.eraseToAnyPublisher()
          }
          guard case 401 = response.statusCode else {
            return Fail(error: error).mapError { $0 }.eraseToAnyPublisher()
          }
          return tokenController.refresh()
            .flatMap { _ in
              request
                .mapError { $0 }
                .handleEvents(receiveCompletion: { completion in
                  switch completion {
                  case .finished:
                    break
                  case .failure(let error):
                    Log.error(error)
                  }
                })
          }
          .eraseToAnyPublisher()
        }
    }
    .mapError { $0 }
    .eraseToAnyPublisher()

  }
}

/// A controller to manage the access-token
public final class TokenController<AuthData> {

  typealias Refresh = (_ currentData: AuthData) -> AnyPublisher<AuthData, Error>

  public var current: AuthData? {
    lock.lock(); defer { lock.unlock() }
    return _storage.value
  }

  private let _refresh: Refresh

  private let _storage: CurrentValueSubject<AuthData?, Never>

  private var isRefreshing: Bool = false

  private let cancellables = Set<AnyCancellable>()

  private let queue = DispatchQueue.init(label: "app.muukii.token-controller", qos: .userInteractive, attributes: [])

  private let lock = NSRecursiveLock()

  init(
    initial: AuthData,
    refresh: @escaping Refresh
  ) {

    self._storage = .init(initial)
    self._refresh = refresh
  }

  public func validate() -> AnyPublisher<AuthData, Never> {

    lock.lock(); defer { lock.unlock() }

    return _storage
      .filter { $0 != nil }
      .map { $0! }
      .first()
      .timeout(.seconds(15), scheduler: queue)
      .eraseToAnyPublisher()

  }

  public func refresh() -> AnyPublisher<AuthData, Error> {

    lock.lock(); defer { lock.unlock() }

    guard isRefreshing == false else {
      return validate().setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    isRefreshing = true

    let token = current

    assert(token != nil, "OOPS!!!")

    _storage.value = nil

    _refresh(token!)
      .receive(on: queue)
      .handleEvents(receiveOutput: { [weak self] output in
        guard let self = self else { return }
        self.lock.lock(); defer { self.lock.unlock() }
        self._storage.value = output
        self.isRefreshing = false
      })
      .start()

    return validate().setFailureType(to: Error.self).eraseToAnyPublisher()

  }
}
