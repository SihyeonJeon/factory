import Foundation

/// Personal Apple Developer team 에서는 Sign in with Apple, Associated Domains
/// (Universal Links) 등 paid-only capability 가 미지원이라 entitlement 자체에
/// 포함하지 못한다. 코드는 그대로 보존하고, UI 진입점만 본 toggle 로 가드한다.
/// Paid Developer Program 전환 시 toggle = true 로 한 줄 변경.
enum PaidDeveloperFeatures {
    static let signInWithAppleAvailable: Bool = false
    static let associatedDomainsAvailable: Bool = false
}
