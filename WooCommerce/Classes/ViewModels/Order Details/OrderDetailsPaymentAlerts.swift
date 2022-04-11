import MessageUI
import UIKit
import WordPressUI

/// A layer of indirection between OrderDetailsViewController and the modal alerts
/// presented to provide user-facing feedback about the progress
/// of the payment collection process
final class OrderDetailsPaymentAlerts {
    private weak var presentingController: UIViewController?

    // Storing this as a weak variable means that iOS should automatically set this to nil
    // when the VC is dismissed, unless there is a retain cycle somewhere else.
    private weak var _modalController: CardPresentPaymentsModalViewController?
    private var modalController: CardPresentPaymentsModalViewController {
        if let controller = _modalController {
            return controller
        } else {
            let controller = CardPresentPaymentsModalViewController(viewModel: readerIsReady(onCancel: {}))
            _modalController = controller
            return controller
        }
    }

    private var name: String = ""
    private var amount: String = ""

    private let transactionType: CardPresentTransactionType
    private let paymentGatewayAccountID: String?
    private let countryCode: String
    private let cardReaderModel: String

    init(transactionType: CardPresentTransactionType,
         presentingController: UIViewController,
         paymentGatewayAccountID: String?,
         countryCode: String,
         cardReaderModel: String) {
        self.transactionType = transactionType
        self.presentingController = presentingController
        self.paymentGatewayAccountID = paymentGatewayAccountID
        self.countryCode = countryCode
        self.cardReaderModel = cardReaderModel
    }

    func presentViewModel(viewModel: CardPresentPaymentsModalViewModel) {
        let controller = modalController
        controller.setViewModel(viewModel)
        if controller.presentingViewController == nil {
            controller.modalPresentationStyle = .custom
            controller.transitioningDelegate = AppDelegate.shared.tabBarController
            presentingController?.present(controller, animated: true)
        }
    }

    func readerIsReady(title: String, amount: String, onCancel: @escaping () -> Void) {
        self.name = title
        self.amount = amount

        // Initial presentation of the modal view controller. We need to provide
        // a customer name and an amount.
        let viewModel = readerIsReady(onCancel: onCancel)
        presentViewModel(viewModel: viewModel)
    }

    func tapOrInsertCard(onCancel: @escaping () -> Void) {
        let viewModel = tapOrInsert(onCancel: onCancel)
        presentViewModel(viewModel: viewModel)
    }

    func displayReaderMessage(message: String) {
        let viewModel = displayMessage(message: message)
        presentViewModel(viewModel: viewModel)
    }

    func processingPayment() {
        let viewModel = processing()
        presentViewModel(viewModel: viewModel)
    }

    func success(printReceipt: @escaping () -> Void, emailReceipt: @escaping () -> Void, noReceiptTitle: String, noReceiptAction: @escaping () -> Void) {
        let viewModel = successViewModel(printReceipt: printReceipt,
                                         emailReceipt: emailReceipt,
                                         noReceiptTitle: noReceiptTitle,
                                         noReceiptAction: noReceiptAction)
        presentViewModel(viewModel: viewModel)
    }

    func error(error: Error, tryAgain: @escaping () -> Void) {
        let viewModel = errorViewModel(error: error, tryAgain: tryAgain)
        presentViewModel(viewModel: viewModel)
    }

    func nonRetryableError(from: UIViewController?, error: Error) {
        let viewModel = nonRetryableErrorViewModel(amount: amount, error: error)
        presentViewModel(viewModel: viewModel)
    }

    func retryableError(from: UIViewController?, tryAgain: @escaping () -> Void) {
        let viewModel = retryableErrorViewModel(tryAgain: tryAgain)
        presentViewModel(viewModel: viewModel)
    }
}

private extension OrderDetailsPaymentAlerts {
    func readerIsReady(onCancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalReaderIsReady(name: name,
                                      amount: amount,
                                      cancelAction: onCancel)
    }

    func tapOrInsert(onCancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalTapCard(name: name, amount: amount, onCancel: onCancel)
    }

    func displayMessage(message: String) -> CardPresentPaymentsModalViewModel {
        CardPresentModalDisplayMessage(name: name, amount: amount, message: message)
    }

    func processing() -> CardPresentPaymentsModalViewModel {
        CardPresentModalProcessing(name: name, amount: amount, transactionType: transactionType)
    }

    func successViewModel(printReceipt: @escaping () -> Void,
                          emailReceipt: @escaping () -> Void,
                          noReceiptTitle: String,
                          noReceiptAction: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        if MFMailComposeViewController.canSendMail() {
            return CardPresentModalSuccess(printReceipt: printReceipt,
                                           emailReceipt: emailReceipt,
                                           noReceiptTitle: noReceiptTitle,
                                           noReceiptAction: noReceiptAction)
        } else {
            return CardPresentModalSuccessWithoutEmail(printReceipt: printReceipt, noReceiptTitle: noReceiptTitle, noReceiptAction: noReceiptAction)
        }
    }

    func errorViewModel(error: Error, tryAgain: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalError(error: error, transactionType: transactionType, primaryAction: tryAgain)
    }

    func retryableErrorViewModel(tryAgain: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalRetryableError(primaryAction: tryAgain)
    }

    func nonRetryableErrorViewModel(amount: String, error: Error) -> CardPresentPaymentsModalViewModel {
        CardPresentModalNonRetryableError(amount: amount, error: error)
    }
}
