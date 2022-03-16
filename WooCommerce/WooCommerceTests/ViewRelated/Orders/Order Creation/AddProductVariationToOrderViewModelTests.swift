import XCTest
import Yosemite
@testable import WooCommerce
@testable import Storage

class AddProductVariationToOrderViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 123
    private let sampleProductID: Int64 = 12
    private var storageManager: StorageManagerType!
    private var storage: StorageType {
        storageManager.viewStorage
    }
    private let stores = MockStoresManager(sessionManager: .testingInstance)

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores.reset()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    func test_view_model_adds_product_variation_rows_with_expected_values() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID,
                                          attributes: [ProductAttribute.fake().copy(siteID: sampleSiteID, attributeID: 1, name: "Color", variation: true),
                                                       ProductAttribute.fake().copy(siteID: sampleSiteID, attributeID: 2, name: "Size", variation: true)])
        let productVariation = sampleProductVariation.copy(attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")])
        insert(productVariation)

        // When
        let viewModel = AddProductVariationToOrderViewModel(siteID: sampleSiteID, product: product, storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.productVariationRows.count, 1)

        let productVariationRow = viewModel.productVariationRows[0]
        XCTAssertFalse(productVariationRow.canChangeQuantity,
                       "Product variation row canChangeQuantity property should be false but is true instead")
        XCTAssertEqual(productVariationRow.name, "Blue - Any Size")
    }

    func test_product_variation_rows_only_include_purchasable_product_variations() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let purchasableProductVariation = sampleProductVariation.copy(productVariationID: 1)
        let nonPurchasableProductVariation = ProductVariation.fake().copy(siteID: sampleSiteID, productVariationID: 2, purchasable: false)
        insert([purchasableProductVariation, nonPurchasableProductVariation])

        // When
        let viewModel = AddProductVariationToOrderViewModel(siteID: sampleSiteID, product: product, storageManager: storageManager)

        // Then
        XCTAssertTrue(viewModel.productVariationRows.contains(where: { $0.productOrVariationID == 1 }),
                      "Product variation rows do not include purchasable product variation")
        XCTAssertFalse(viewModel.productVariationRows.contains(where: { $0.productOrVariationID == 2 }),
                       "Product variation rows include non-purchasable product variation")
    }

    func test_scrolling_indicator_appears_only_during_sync() {
        // Given
        let product = Product.fake()
        let viewModel = AddProductVariationToOrderViewModel(siteID: sampleSiteID, product: product, storageManager: storageManager, stores: stores)
        XCTAssertFalse(viewModel.shouldShowScrollIndicator, "Scroll indicator is not disabled at start")
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, onCompletion):
                XCTAssertTrue(viewModel.shouldShowScrollIndicator, "Scroll indicator is not enabled during sync")
                onCompletion(nil)
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.sync(pageNumber: 1, pageSize: 25, onCompletion: { _ in })

        // Then
        XCTAssertFalse(viewModel.shouldShowScrollIndicator, "Scroll indicator is not disabled after sync ends")
    }

    func test_sync_status_updates_as_expected_for_empty_product_variation_list() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let viewModel = AddProductVariationToOrderViewModel(siteID: sampleSiteID, product: product, storageManager: storageManager, stores: stores)
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, onCompletion):
                XCTAssertEqual(viewModel.syncStatus, .firstPageSync)
                onCompletion(nil)
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.sync(pageNumber: 1, pageSize: 25, onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.syncStatus, .empty)
    }

    func test_sync_status_updates_as_expected_when_product_variations_are_synced() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let viewModel = AddProductVariationToOrderViewModel(siteID: sampleSiteID, product: product, storageManager: storageManager, stores: stores)
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, onCompletion):
                XCTAssertEqual(viewModel.syncStatus, .firstPageSync)
                self.insert(self.sampleProductVariation)
                onCompletion(nil)
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.sync(pageNumber: 1, pageSize: 25, onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.syncStatus, .results)
    }

    func test_sync_status_does_not_change_while_syncing_when_storage_contains_product_variations() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        insert(sampleProductVariation)

        let viewModel = AddProductVariationToOrderViewModel(siteID: sampleSiteID, product: product, storageManager: storageManager, stores: stores)
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, onCompletion):
                XCTAssertEqual(viewModel.syncStatus, .results)
                onCompletion(nil)
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.sync(pageNumber: 1, pageSize: 25, onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.syncStatus, .results)
    }

    func test_onLoadTrigger_triggers_initial_product_variation_sync() {
        // Given
        let viewModel = AddProductVariationToOrderViewModel(siteID: sampleSiteID, product: Product.fake(), storageManager: storageManager, stores: stores)
        var timesSynced = 0
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case .synchronizeProductVariations:
                timesSynced += 1
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.onLoadTrigger.send()
        viewModel.onLoadTrigger.send()

        // Then
        XCTAssertEqual(timesSynced, 1)
    }

    func test_product_variations_sorted_by_menu_order_and_id() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let variation1 = sampleProductVariation.copy(productVariationID: 3, menuOrder: 1)
        let variation2 = sampleProductVariation.copy(productVariationID: 2, menuOrder: 0)
        let variation3 = sampleProductVariation.copy(productVariationID: 1, menuOrder: 0)
        insert([variation1, variation2, variation3])

        // When
        let viewModel = AddProductVariationToOrderViewModel(siteID: sampleSiteID, product: product, storageManager: storageManager, stores: stores)

        // Then
        let sortedProductVariationIDs = viewModel.productVariationRows.map { $0.productOrVariationID }
        XCTAssertEqual(sortedProductVariationIDs, [2, 1, 3])
    }
}

// MARK: - Utils
private extension AddProductVariationToOrderViewModelTests {
    /// Insert a `ProductVariation` into storage
    func insert(_ readOnlyVariation: Yosemite.ProductVariation) {
        let productVariation = storage.insertNewObject(ofType: StorageProductVariation.self)
        productVariation.update(with: readOnlyVariation)

        // Inserts the attributes from the read-only product variation.
        var storageAttributes = [StorageAttribute]()
        for readOnlyAttribute in readOnlyVariation.attributes {
            let newStorageAttribute = storage.insertNewObject(ofType: Storage.GenericAttribute.self)
            newStorageAttribute.update(with: readOnlyAttribute)
            storageAttributes.append(newStorageAttribute)
        }
        productVariation.attributes = NSOrderedSet(array: storageAttributes)
    }

    /// Insert an array of `ProductVariation`s into storage
    func insert(_ readOnlyVariations: [Yosemite.ProductVariation]) {
        for readOnlyVariation in readOnlyVariations {
            insert(readOnlyVariation)
        }
    }

    /// A purchasable product variation.
    ///
    var sampleProductVariation: Yosemite.ProductVariation {
        ProductVariation.fake().copy(siteID: sampleSiteID,
                                     productID: sampleProductID,
                                     purchasable: true)
    }
}
