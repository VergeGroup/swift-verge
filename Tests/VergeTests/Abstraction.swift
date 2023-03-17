
import Verge

protocol MyViewModelType: StoreComponentType where WrappedStore.State == String, WrappedStore.Activity == Int {

}

final class Concrete: MyViewModelType {

  let store: Verge.Store<String, Int>

  init() {
    store = .init(initialState: .init())

    sinkState { _ in

    }

    commit { _ in

    }
  }

}

final class Controller<ViewModel: MyViewModelType> {

  init(viewModel: ViewModel) {
    let _: Changes<String> = viewModel.state

    viewModel.send(1)
  }

}
