import Foundation
import WordPressAuthenticator

/// For holding the custom help center content URL
/// and analytics tracking values
///
struct CustomHelpCenterContent {
    /// Custom help center web page's URL
    ///
    let helpCenterContentURL: URL

    /// Provides a dictionary for analytics tracking
    ///
    let trackingProperties: [String: String]
}

extension CustomHelpCenterContent {
    enum Key: String {
        case step = "source_step"
        case flow = "source_flow"
        case url = "help_content_url"
    }

    /// Initializes a `CustomHelpCenterContent` instance using `Step` and `Flow` from `AuthenticatorAnalyticsTracker`
    ///
    init?(step: AuthenticatorAnalyticsTracker.Step, flow: AuthenticatorAnalyticsTracker.Flow) {
        switch step {
        case .start where flow == .loginWithSiteAddress:
            helpCenterContentURL = WooConstants.URLs.helpCenterForEnterStoreAddress.asURL()
        default:
            return nil
        }

        trackingProperties = [
            Key.step.rawValue: step.rawValue,
            Key.flow.rawValue: flow.rawValue,
            Key.url.rawValue: helpCenterContentURL.absoluteString
        ]
    }
}
