import XCTest
@testable import Networking
@testable import Storage
@testable import Yosemite


/// RefundStore Unit Tests
///
class RefundStoreTests: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Testing SiteID
    ///
    private let sampleSiteID = 999

    /// Testing OrderID
    ///
    private let sampleOrderID = 560

    /// Testing RefundID
    ///
    private let sampleRefundID = 590

    /// Testing Page Number
    ///
    private let defaultPageNumber = 1

    /// Testing Page Size
    ///
    private let defaultPageSize = 25


    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    override func tearDown() {
        super.tearDown()
        // anything that needs cleared after each unit test, should be added here.
    }


    // MARK: - RefundAction.synchronizeRefunds

    /// Verifies that RefundAction.synchronizeRefunds effectively persists any retrieved refunds.
    ///
    func testRetrieveRefundsEffectivelyPersistsRetrievedRefunds() {
        let expectation = self.expectation(description: "Retrieve refunds")
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "refunds", filename: "refunds-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Refund.self), 0)

        let action = RefundAction.synchronizeRefunds(siteID: sampleSiteID, orderID: sampleOrderID, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Refund.self), 2)
            XCTAssertNil(error)

            expectation.fulfill()
        }

        refundStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `RefundAction.synchronizeRefunds` effectively persists all of the refund fields
    /// correctly across the related `Refund` entities (OrderItemRefund, for example).
    ///
    func testRetrieveRefundsEffectivelyPersistsRefundFieldsAndRelatedObjects() {
        let expectation = self.expectation(description: "Persist refunds list")
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteRefund = sampleRefund()

        network.simulateResponse(requestUrlSuffix: "refunds", filename: "refunds-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Refund.self), 0)

        let action = RefundAction.synchronizeRefunds(siteID: sampleSiteID, orderID: sampleOrderID, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
            XCTAssertNil(error)

            let storedRefund = self.viewStorage.loadRefund(siteID: self.sampleSiteID, orderID: self.sampleOrderID, refundID: self.sampleRefundID)
            let readOnlyStoredRefund = storedRefund?.toReadOnly()
            XCTAssertNotNil(storedRefund)
            XCTAssertNotNil(readOnlyStoredRefund)
            XCTAssertEqual(readOnlyStoredRefund, remoteRefund)

            expectation.fulfill()
        }

        refundStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}


// MARK: - Private Helpers
//
private extension RefundStoreTests {

    /// Generate a sample Refund
    ///
    func sampleRefund(_ siteID: Int? = nil) -> Networking.Refund {
        let testSiteID = siteID ?? sampleSiteID
        let testDate = date(with: "2019-10-09T16:18:23")
        return Refund(refundID: sampleRefundID,
                      orderID: sampleOrderID,
                      siteID: testSiteID,
                      dateCreated: testDate,
                      amount: "18.00",
                      reason: "Only 1 black hoodie left. Inventory count was off. My bad!",
                      refundedByUserID: 1,
                      isAutomated: true,
                      createAutomated: false,
                      items: [sampleOrderItem()])
    }

    /// Generate a sample OrderItem
    ///
    func sampleOrderItem() -> Networking.OrderItemRefund {
        return OrderItemRefund(itemID: 73,
                               name: "Ninja Silhouette",
                               productID: 22,
                               variationID: 0,
                               quantity: -1,
                               price: 18,
                               sku: "T-SHIRT-NINJA-SILHOUETTE",
                               subtotal: "-18.00",
                               subtotalTax: "0.00",
                               taxClass: "",
                               taxes: [],
                               total: "-18.00",
                               totalTax: "0.00")
    }

    /// Format GMT string to Date type
    ///
    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}
