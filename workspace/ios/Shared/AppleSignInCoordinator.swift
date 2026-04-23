import AuthenticationServices
import CryptoKit
import Foundation
import Security
import Supabase
import UIKit

@MainActor
protocol AppleSignInCoordinating: AnyObject {
    func signIn() async throws
}

@MainActor
final class AppleSignInCoordinator: NSObject, AppleSignInCoordinating {
    private var currentNonce: String?
    private var currentState: String?
    private var continuation: CheckedContinuation<Void, Error>?
    private var controller: ASAuthorizationController?

    func signIn() async throws {
        guard continuation == nil else {
            throw AppleSignInError.requestAlreadyInFlight
        }

        let request = makeRequest()
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        self.controller = controller

        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    private func makeRequest() -> ASAuthorizationAppleIDRequest {
        let nonce = Self.randomNonce()
        let state = UUID().uuidString.lowercased()

        currentNonce = nonce
        currentState = state

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
        request.state = state
        return request
    }

    private func finish(with result: Result<Void, Error>) {
        let continuation = continuation
        self.continuation = nil
        controller = nil
        currentNonce = nil
        currentState = nil

        switch result {
        case .success:
            continuation?.resume()
        case .failure(let error):
            continuation?.resume(throwing: error)
        }
    }

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        result.reserveCapacity(length)

        while result.count < length {
            var randomBytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
            guard status == errSecSuccess else {
                fatalError("Unable to generate nonce. OSStatus=\(status)")
            }

            randomBytes.forEach { byte in
                if result.count < length, Int(byte) < charset.count {
                    result.append(charset[Int(byte)])
                }
            }
        }

        return result
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

@MainActor
extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            finish(with: .failure(AppleSignInError.invalidCredential))
            return
        }

        guard let identityTokenData = credential.identityToken else {
            finish(with: .failure(AppleSignInError.missingIdentityToken))
            return
        }

        guard let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            finish(with: .failure(AppleSignInError.invalidIdentityToken))
            return
        }

        guard let nonce = currentNonce else {
            finish(with: .failure(AppleSignInError.missingNonce))
            return
        }

        if let currentState, let credentialState = credential.state, credentialState != currentState {
            finish(with: .failure(AppleSignInError.invalidState))
            return
        }

        Task {
            do {
                _ = try await SupabaseService.shared.client.auth.signInWithIdToken(
                    credentials: .init(
                        provider: .apple,
                        idToken: identityToken,
                        nonce: nonce
                    )
                )
                finish(with: .success(()))
            } catch {
                finish(with: .failure(error))
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        finish(with: .failure(error))
    }
}

@MainActor
extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        if let keyWindow = scenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        {
            return keyWindow
        }

        if let firstWindow = scenes
            .flatMap(\.windows)
            .first
        {
            return firstWindow
        }

        return ASPresentationAnchor()
    }
}

enum AppleSignInError: LocalizedError {
    case requestAlreadyInFlight
    case invalidCredential
    case missingIdentityToken
    case invalidIdentityToken
    case missingNonce
    case invalidState

    var errorDescription: String? {
        switch self {
        case .requestAlreadyInFlight:
            return "Apple Sign In request already in progress."
        case .invalidCredential:
            return "Apple Sign In returned an unexpected credential type."
        case .missingIdentityToken:
            return "Apple Sign In did not provide an identity token."
        case .invalidIdentityToken:
            return "Apple Sign In returned an invalid identity token."
        case .missingNonce:
            return "Apple Sign In nonce is missing."
        case .invalidState:
            return "Apple Sign In state validation failed."
        }
    }
}
