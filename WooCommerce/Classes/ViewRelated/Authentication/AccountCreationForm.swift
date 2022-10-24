import SwiftUI

/// Hosting controller that wraps an `AccountCreationForm`.
final class AccountCreationFormHostingController: UIHostingController<AccountCreationForm> {
    init(viewModel: AccountCreationFormViewModel, completion: @escaping () -> Void) {
        super.init(rootView: AccountCreationForm(viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController.
        rootView.completion = {
            completion()
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A form that allows the user to create a WPCOM account with an email and password.
struct AccountCreationForm: View {
    @Environment(\.customOpenURL) var customOpenURL

    /// Triggered when the account is created and the app is authenticated.
    var completion: (() -> Void) = {}

    @ObservedObject private var viewModel: AccountCreationFormViewModel

    @State private var isPerformingTask = false

    init(viewModel: AccountCreationFormViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                // Header.
                VStack(alignment: .leading, spacing: Layout.horizontalSpacing) {
                    Text(Localization.title)
                        .largeTitleStyle()
                    Text(Localization.subtitle)
                        .foregroundColor(Color(.secondaryLabel))
                        .bodyStyle()
                }

                // Form fields.
                VStack(spacing: Layout.verticalSpacingBetweenFields) {
                    AccountCreationFormFieldView(viewModel: .init(header: Localization.emailFieldTitle,
                                                                  placeholder: Localization.emailFieldPlaceholder,
                                                                  keyboardType: .emailAddress,
                                                                  text: $viewModel.email,
                                                                  isSecure: false,
                                                                  errorMessage: viewModel.emailErrorMessage))
                    AccountCreationFormFieldView(viewModel: .init(header: Localization.passwordFieldTitle,
                                                                  placeholder: Localization.passwordFieldPlaceholder,
                                                                  keyboardType: .default,
                                                                  text: $viewModel.password,
                                                                  isSecure: true,
                                                                  errorMessage: viewModel.passwordErrorMessage))
                    AttributedText(tosAttributedText)
                        .attributedTextLinkColor(Color(.textLink))
                }

                // CTA to submit the form.
                Button(Localization.submitButtonTitle) {
                    Task { @MainActor in
                        isPerformingTask = true
                        let result = await viewModel.createAccount()
                        isPerformingTask = false
                        switch result {
                        case .success:
                            completion()
                        case .failure:
                            break
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!(viewModel.isEmailValid && viewModel.isPasswordValid) || isPerformingTask)
            }
            .padding(.init(top: 0, leading: Layout.horizontalSpacing, bottom: 0, trailing: Layout.horizontalSpacing))
        }
    }
}

private extension AccountCreationForm {
    var tosAttributedText: NSAttributedString {
        let result = NSMutableAttributedString(
            string: .localizedStringWithFormat(Localization.tosFormat, Localization.tos),
            attributes: [
                .foregroundColor: UIColor.label,
                .font: UIFont.body
            ]
        )
        result.replaceFirstOccurrence(
            of: Localization.tos,
            with: NSAttributedString(
                string: Localization.tos,
                attributes: [
                    .font: UIFont.body,
                    .link: Constants.tosURL
                ]
            ))
        return result
    }

    enum Constants {
        static let tosURL = WooConstants.URLs.termsOfService.asURL()
    }

    enum Localization {
        static let title = NSLocalizedString("Get started in minutes", comment: "Title for the account creation form.")
        // TODO-7891: support login navigation.
        static let subtitle = NSLocalizedString("First, let’s create your account.", comment: "Subtitle for the account creation form.")
        static let emailFieldTitle = NSLocalizedString("Your email address", comment: "Title of the email field on the account creation form.")
        static let emailFieldPlaceholder = NSLocalizedString("Email address", comment: "Placeholder of the email field on the account creation form.")
        static let passwordFieldTitle = NSLocalizedString("Choose a password", comment: "Title of the password field on the account creation form.")
        static let passwordFieldPlaceholder = NSLocalizedString("Password", comment: "Placeholder of the password field on the account creation form.")
        static let tosFormat = NSLocalizedString("By continuing, you agree to our %1$@.", comment: "Terms of service format on the account creation form.")
        static let tos = NSLocalizedString("Terms of Service", comment: "Terms of service link on the account creation form.")
        static let submitButtonTitle = NSLocalizedString("Get started", comment: "Title of the submit button on the account creation form.")
    }

    enum Layout {
        static let verticalSpacing: CGFloat = 40
        static let verticalSpacingBetweenFields: CGFloat = 16
        static let horizontalSpacing: CGFloat = 16
    }
}

struct AccountCreationForm_Previews: PreviewProvider {
    static var previews: some View {
        AccountCreationForm(viewModel: .init())
            .preferredColorScheme(.light)

        AccountCreationForm(viewModel: .init())
            .preferredColorScheme(.dark)
            .dynamicTypeSize(.xxxLarge)
    }
}
