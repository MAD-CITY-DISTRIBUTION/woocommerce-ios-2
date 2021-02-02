import UIKit
import Yosemite

final class CreateShippingLabelFormViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let viewModel: CreateShippingLabelFormViewModel

    /// Init
    ///
    init(order: Order) {
        viewModel = CreateShippingLabelFormViewModel(order: order)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureMainView()
        configureTableView()
        registerTableViewCells()
    }
}

// MARK: - View Configuration
//
private extension CreateShippingLabelFormViewController {

    func configureNavigationBar() {
        title = Localization.titleView
        removeNavigationBackBarButtonText()
    }

    func configureMainView() {
        view.backgroundColor = .listForeground
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listForeground
        tableView.separatorStyle = .none

        registerTableViewCells()

        tableView.dataSource = self
    }

    func registerTableViewCells() {
        for row in RowType.allCases {
            tableView.registerNib(for: row.type)
        }
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension CreateShippingLabelFormViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.type.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - Cell configuration
//
private extension CreateShippingLabelFormViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as ShippingLabelFormStepTableViewCell where row.type == .shipFrom:
            configureShipFrom(cell: cell)
        case let cell as ShippingLabelFormStepTableViewCell where row.type == .shipTo:
            configureShipTo(cell: cell)
        case let cell as ShippingLabelFormStepTableViewCell where row.type == .packageDetails:
            configurePackageDetails(cell: cell)
        case let cell as ShippingLabelFormStepTableViewCell where row.type == .shippingCarrierAndRates:
            configureShippingCarrierAndRates(cell: cell)
        case let cell as ShippingLabelFormStepTableViewCell where row.type == .paymentMethod:
            configurePaymentMethod(cell: cell)
        default:
            fatalError()
            break
        }
    }

    func configureShipFrom(cell: ShippingLabelFormStepTableViewCell) {
        // TODO: to be implemented in the future
    }

    func configureShipTo(cell: ShippingLabelFormStepTableViewCell) {
        // TODO: to be implemented in the future
    }

    func configurePackageDetails(cell: ShippingLabelFormStepTableViewCell) {
        // TODO: to be implemented in the future
    }

    func configureShippingCarrierAndRates(cell: ShippingLabelFormStepTableViewCell) {
        // TODO: to be implemented in the future
    }

    func configurePaymentMethod(cell: ShippingLabelFormStepTableViewCell) {
        // TODO: to be implemented in the future
    }

}

extension CreateShippingLabelFormViewController {

    struct Section: Equatable {
        let rows: [Row]
    }

    struct Row: Equatable {
        let type: RowType
        let dataState: DateState
        let displayMode: DisplayMode
    }

    /// Each row has a data state
    enum DateState {
        /// the data are validated
        case validated

        /// the data still need to be validated
        case pending
    }

    /// Each row has a UI state
    enum DisplayMode {
        /// the row is not greyed out and is available for edit (a disclosure indicator is shown in the accessory view) and
        /// "Continue" CTA is shown to edit the row details
        case editable

        /// the row is greyed out
        case disabled
    }

    enum RowType: CaseIterable {
        case shipFrom
        case shipTo
        case packageDetails
        case shippingCarrierAndRates
        case paymentMethod

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .shipFrom, .shipTo, .packageDetails, .shippingCarrierAndRates, .paymentMethod:
                return ShippingLabelFormStepTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

private extension CreateShippingLabelFormViewController {
    enum Localization {
        static let titleView = NSLocalizedString("Create Shipping Label", comment: "Create Shipping Label navigation title")
    }
}
