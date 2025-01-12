
import Verge

struct RootState: Equatable {

  struct Nested: Equatable {}

  var nested: Nested = .init()

}

final class RootStore: Store<RootState, Never>, @unchecked Sendable {

}

final class Service: StoreDriverType {

  var store: RootStore { fatalError() }

  init() {

  }

}

final class SpecificService: StoreDriverType {

  var scope: WritableKeyPath<RootState, RootState.Nested> & Sendable { \.nested }

  var store: RootStore { fatalError() }

  init() {

    _ = sinkState { state in

      let _: Changes<RootState.Nested> = state
    }

  }

}

final class ViewModel: StoreDriverType {

  struct State: Equatable {}

  let store: Store<State, Never> = .init(initialState: .init())

  init() {

    commit { _ in

    }

    _ = sinkState { state in
      let _: Changes<State> = state
    }

  }

}

// MARK: - Abstraction

protocol MyViewModelType: StoreDriverType where TargetStore.State == String, TargetStore.Activity == Int {

}

final class Concrete: MyViewModelType {

  let store: Verge.Store<String, Int>

  init() {
    store = .init(initialState: .init())

    _ = sinkState { _ in

    }

    commit { _ in

    }

  }

}

final class Controller<ViewModel: MyViewModelType> where ViewModel.Scope == ViewModel.TargetStore.State {

  init(viewModel: ViewModel) {

    let _: Changes<String> = viewModel.state

    viewModel.send(1)
  }

}
