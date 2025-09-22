import SwiftUI
import Verge

struct BookVergeTaskManager: View, PreviewProvider {
  var body: some View {
    Content()
  }

  static var previews: some View {
    Self()
  }

  private struct Content: View {

    @StateObject var viewModel: ViewModel = .init()
    @State var count = 0

    var body: some View {
      VStack {

        Button("Wait") {
          count += 1
          viewModel.fetch(token: count.description)
        }

        Button("Override") {
          count += 1
          viewModel.fetchOverride(token: count.description)
        }

        Button("Cancel All") {
          viewModel.cancelAll()
        }

      }
    }
  }

  final class ViewModel: StoreComponentType, ObservableObject {

    struct State: Equatable {

    }

    let store = Store<State, Never>(initialState: .init())

    init() {

    }

    enum _Key: TaskKeyType {

    }

    func cancelAll() {
      Task {
        await store.taskManager.cancelAll()
      }
    }

    func fetchOverride(token: String) {
      Task {
        let ref = await store.taskManager.task(
          label: token,
          key: .init(_Key.self),
          mode: .dropCurrent
        ) {
          await networking(token: token)
        }

        let r = Resource(name: token)

        Task {
          print("-> Ref", token)
          let _ = try? await ref.value
          print("<- Ref", token)
          withExtendedLifetime(r) {}
        }
      }
    }

    func fetch(token: String) {
      Task {
        let ref = await store.taskManager.task(
          label: token,
          key: .init(_Key.self),
          mode: .waitInCurrent
        ) {
          await networking(token: token)
        }

        let r = Resource(name: token)

        Task {
          print("-> Ref", token)
          let _ = try? await ref.value
          print("<- Ref", token)
          withExtendedLifetime(r) {}
        }
      }
    }

  }

}

private final class Resource {

  private let name: String

  init(name: String) {
    self.name = name
  }

  deinit {
    print("Deinit", name)
  }
}

private func networking(token: String) async {
  print("✈️ Start", token)
  try? await Task.sleep(nanoseconds: 2_000_000_000)
  if Task.isCancelled {
    print("❌ Cancelled", token)
  } else {
    print("✅ Done", token)
  }
}
