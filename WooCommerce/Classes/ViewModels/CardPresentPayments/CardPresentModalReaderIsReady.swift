import UIKit
import Yosemite

/// The card reader is ready.
final class CardPresentModalReaderIsReady: CardPresentPaymentsModalViewModel {

    /// Customer name
    private let name: String

    /// Charge amount
    private let amount: String

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode = .secondaryOnlyAction

    var topTitle: String {
        name
    }

    var topSubtitle: String? {
        amount
    }

    let image: UIImage = .cardPresentImage

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String? = Localization.readerIsReady

    let bottomSubtitle: String? = Localization.tapInsertOrSwipe

    var accessibilityLabel: String? {
        guard let bottomTitle = bottomTitle else {
            return topTitle
        }

        return topTitle + bottomTitle
    }

    /// Closure to execute when cancel button is tapped
    private let cancelAction: () -> Void

    init(name: String,
         amount: String,
         cancelAction: @escaping () -> Void) {
        self.name = name
        self.amount = amount
        self.cancelAction = cancelAction
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        //
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        cancelAction()
        viewController?.dismiss(animated: true, completion: nil)
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        //
    }
}

private extension CardPresentModalReaderIsReady {
    enum Localization {
        static let readerIsReady = NSLocalizedString(
            "Reader is ready",
            comment: "Indicates the status of a card reader. Presented to users when payment collection starts"
        )

        static let tapInsertOrSwipe = NSLocalizedString(
            "Tap, insert or swipe to pay",
            comment: "Indicates the action expected from a user. Presented to users when payment collection starts"
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to cancel a payment"
        )
    }
}
