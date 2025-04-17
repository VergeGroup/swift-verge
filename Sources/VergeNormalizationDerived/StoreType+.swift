import Verge
import Normalization

extension StoreType {
  
  public func normalizedStorage<Selector: StorageSelector>(_ selector: Selector) -> NormalizedStoragePath<Self, Selector> {
    .init(store: self, storageSelector: selector)
  }
  
}
