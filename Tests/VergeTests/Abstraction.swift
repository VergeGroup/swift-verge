
import Verge

protocol MyViewModelType: StoreComponentType where WrappedStore.State == String {

}

final class Controller<ViewModel: MyViewModelType> {

  init(viewModel: ViewModel) {
    let _: Changes<String> = viewModel.state
  }

}
