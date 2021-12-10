import Yosemite
import protocol Storage.StorageManagerType

/// View model for `AddProductToOrder`.
///
final class AddProductToOrderViewModel: ObservableObject {
    private let siteID: Int64
    private let storageManager: StorageManagerType

    /// Product types excluded from the product list.
    /// For now, only non-variable product types are supported.
    ///
    private let excludedProductTypes: [ProductType] = [ProductType.variable]

    /// Product statuses included in the product list.
    /// Only published or private products can be added to an order.
    ///
    private let includedProductStatuses: [ProductStatus] = [ProductStatus.publish, ProductStatus.privateStatus]

    /// All products that can be added to an order.
    ///
    private var products: [Product] {
        return productsResultsController.fetchedObjects.filter {
            let hasValidProductType = !excludedProductTypes.contains( $0.productType )
            let hasValidProductStatus = includedProductStatuses.contains( $0.productStatus )
            return hasValidProductType && hasValidProductStatus
        }
    }

    /// View models for each product row
    ///
    var productRows: [ProductRowViewModel] {
        products.map { .init(product: $0, canChangeQuantity: false) }
    }

    // MARK: Sync & Storage properties

    /// Current sync status; used to determine what list view to display.
    ///
    @Published private(set) var syncStatus: SyncStatus = .none

    /// SyncCoordinator: Keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator = SyncingCoordinator()

    /// Tracks if there are more products to sync from remote.
    ///
    var hasMoreProducts: Bool {
        guard let highestPageBeingSynced = syncingCoordinator.highestPageBeingSynced else {
            return false
        }

        return highestPageBeingSynced * syncingCoordinator.pageSize > productsResultsController.numberOfObjects
    }

    /// View models of the ghost rows used during the loading process.
    ///
    var ghostRows: [ProductRowViewModel] {
        return Array(0..<6).map { index in
            ProductRowViewModel(product: sampleGhostProduct(id: index), canChangeQuantity: false)
        }
    }

    /// Products Results Controller.
    ///
    private lazy var productsResultsController: ResultsController<StorageProduct> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
        return resultsController
    }()

    init(siteID: Int64, storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.storageManager = storageManager

        configureSyncingCoordinator()
        configureProductsResultsController()
    }
}

// MARK: - SyncingCoordinatorDelegate & Sync Methods
extension AddProductToOrderViewModel: SyncingCoordinatorDelegate {
    /// Sync products from remote.
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: ((Bool) -> Void)?) {
        if products.isEmpty {
            transitionToInitialSyncingState()
        }
        let action = ProductAction.synchronizeProducts(siteID: siteID,
                                                       pageNumber: pageNumber,
                                                       pageSize: pageSize,
                                                       stockStatus: nil,
                                                       productStatus: nil,
                                                       productType: nil,
                                                       productCategory: nil,
                                                       sortOrder: .nameAscending,
                                                       shouldDeleteStoredProductsOnFirstPage: false) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing products during order creation: \(error)")
            case .success:
                self.updateProductsResultsController()
            }

            self.transitionToResultsUpdatedState()
            onCompletion?(result.isSuccess)
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Sync first page of products from remote if needed.
    ///
    func syncFirstPage() {
        syncingCoordinator.synchronizeFirstPage()
    }

    /// Sync next page of products from remote.
    ///
    func syncNextPage() {
        let lastIndex = productsResultsController.numberOfObjects - 1
        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: lastIndex)
    }
}

// MARK: - Finite State Machine Management
private extension AddProductToOrderViewModel {
    /// Update state for initial sync from remote.
    ///
    func transitionToInitialSyncingState() {
        syncStatus = .firstPageSync
    }

    /// Update state after sync is complete.
    ///
    func transitionToResultsUpdatedState() {
        syncStatus = products.isNotEmpty ? .results: .empty
    }
}

// MARK: - Configuration
private extension AddProductToOrderViewModel {
    /// Fetches products from storage. If there are no stored products, trigger a sync request.
    ///
    func configureProductsResultsController() {
        updateProductsResultsController()
        transitionToResultsUpdatedState()
    }

    /// Fetches products from storage.
    ///
    func updateProductsResultsController() {
        do {
            try productsResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching products for new order: \(error)")
        }
    }

    /// Setup: Syncing Coordinator
    ///
    func configureSyncingCoordinator() {
        syncingCoordinator.delegate = self
    }
}

// MARK: - Utils
extension AddProductToOrderViewModel {
    /// Represents possible statuses for syncing products
    ///
    enum SyncStatus {
        case firstPageSync
        case results
        case empty
        case none
    }

    /// Used for ghost list view while syncing
    ///
    private func sampleGhostProduct(id: Int64) -> Product {
        return Product().copy(productID: id,
                              name: "Love Ficus",
                              sku: "123456",
                              price: "20",
                              stockQuantity: 7,
                              stockStatusKey: "instock")
    }
}
