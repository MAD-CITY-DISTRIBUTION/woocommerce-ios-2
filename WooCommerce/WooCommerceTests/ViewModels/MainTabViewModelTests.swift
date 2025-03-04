import XCTest
import TestKit

@testable import WooCommerce

import Yosemite

/// Test cases for `MainTabViewModel`.
final class MainTabViewModelTests: XCTestCase {
    private let sampleStoreID: Int64 = 35

    func test_onViewDidAppear_will_save_the_installation_date() throws {
        // Given
        let storesManager = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        storesManager.reset()

        let viewModel = MainTabViewModel(storesManager: storesManager)

        assertEmpty(storesManager.receivedActions)

        // When
        viewModel.onViewDidAppear()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 1)

        let action = try XCTUnwrap(storesManager.receivedActions.first as? AppSettingsAction)
        switch action {
        case let .setInstallationDateIfNecessary(date, _):
            let interval = abs(date.timeIntervalSince(Date()))
            XCTAssertLessThanOrEqual(interval, 100)
        default:
            XCTFail("Expected action to be .setInstallationDateIfNecessary")
        }
    }

    func test_when_user_is_not_logged_in_then_onViewDidAppear_will_not_save_the_installation_date() throws {
        // Given
        let storesManager = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        storesManager.reset()

        let viewModel = MainTabViewModel(storesManager: storesManager)

        assertEmpty(storesManager.receivedActions)

        // When
        viewModel.onViewDidAppear()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 0)
    }

    func test_loadHubMenuTabBadge_when_should_show_reviews_badge_only_calls_onMenuBadgeShouldBeDisplayed_with_type_secondary() {
        // Given
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.setStoreId(sampleStoreID)
        let storesManager = MockStoresManager(sessionManager: sessionManager)

        storesManager.whenReceivingAction(ofType: NotificationCountAction.self) { action in
            switch action {
            case let .load(_, type, onCompletion):
                if case .kind(.comment) = type {
                    let pendingNotifications = 23
                    onCompletion(pendingNotifications)
                }
            default:
                break
            }
        }

        let viewModel = MainTabViewModel(storesManager: storesManager)
        var returnedType: NotificationBadgeType?
        viewModel.onMenuBadgeShouldBeDisplayed = { type in
            returnedType = type

        }

        // When
        viewModel.loadHubMenuTabBadge()

        // Then
        waitUntil {
            returnedType == .secondary
        }
    }

    func test_loadHubMenuTabBadge_when_reviews_badge_should_be_hidden_calls_onMenuBadgeShouldBeHidden() {
        // Given
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.setStoreId(sampleStoreID)
        let storesManager = MockStoresManager(sessionManager: sessionManager)

        storesManager.whenReceivingAction(ofType: NotificationCountAction.self) { action in
            switch action {
            case let .load(_, type, onCompletion):
                if case .kind(.comment) = type {
                    onCompletion(0)
                }
            default:
                break
            }
        }

        let viewModel = MainTabViewModel(storesManager: storesManager)
        var onMenuBadgeShouldBeHiddenWasCalled = false
        viewModel.onMenuBadgeShouldBeHidden = {
            onMenuBadgeShouldBeHiddenWasCalled = true

        }

        // When
        viewModel.loadHubMenuTabBadge()

        // Then
        waitUntil {
            onMenuBadgeShouldBeHiddenWasCalled
        }
    }
}
