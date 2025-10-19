//
//  AuthService.swift
//  swapride
//
//  Created by GitHub Copilot on 19.10.2025.
//

import Foundation
import Combine
import FirebaseAuth
import AuthenticationServices
import CryptoKit
import UIKit

@MainActor
final class AuthService: NSObject, ObservableObject {
    @Published var user: User?
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    
    override init() {
        super.init()
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.user = user }
        }
    }
    
    deinit {
        if let h = authHandle { Auth.auth().removeStateDidChangeListener(h) }
    }
    
    // MARK: - Apple
    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // MARK: - Generic OAuth (Google, Facebook, Microsoft)
    func signInWithProvider(_ providerID: String, scopes: [String] = [], customParameters: [String: String] = [:], presenting: UIViewController) async throws {
        let provider = OAuthProvider(providerID: providerID)
        if !scopes.isEmpty { provider.scopes = scopes }
        if !customParameters.isEmpty { provider.customParameters = customParameters }
        return try await withCheckedThrowingContinuation { continuation in
            let adapter = AuthUIDelegateAdapter(presenter: presenting)
            provider.getCredentialWith(adapter) { credential, error in
                if let error = error { return continuation.resume(throwing: error) }
                guard let credential = credential else {
                    return continuation.resume(throwing: NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing credential"]))
                }
                Auth.auth().signIn(with: credential) { _, err in
                    if let err = err { continuation.resume(throwing: err) }
                    else { continuation.resume() }
                }
            }
        }
    }
    
    // Helper to get a presenting view controller from SwiftUI
    func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              var top = window.rootViewController else { return nil }
        while let presented = top.presentedViewController { top = presented }
        return top
    }

    func signOut() {
        try? Auth.auth().signOut()
    }
}

// MARK: - Firebase Auth uiDelegate adapter
// Avoid retroactive conformance by providing a small adapter object that
// conforms to AuthUIDelegate and holds a weak reference to the presenter.
final class AuthUIDelegateAdapter: NSObject, AuthUIDelegate {
    
    weak var presenter: UIViewController?
    init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        presenter?.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        presenter?.dismiss(animated: flag, completion: completion)
    }
}


// MARK: - ASAuthorizationControllerDelegate
extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        guard let nonce = currentNonce else { return }
        guard let appleIDToken = appleIDCredential.identityToken else { return }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else { return }
        // FirebaseAuth 12.x: use the new Swift-friendly API for Apple credential
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        Auth.auth().signIn(with: credential) { _, _ in }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // No-op, you can publish error state here if needed
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let keyWindow = scenes.compactMap({ $0.windows.first(where: { $0.isKeyWindow }) }).first {
            return keyWindow
        }
        if let anyWindow = scenes.first?.windows.first {
            return anyWindow
        }
        if #available(iOS 26.0, *) {
            if let scene = scenes.first {
                return UIWindow(windowScene: scene)
            }
            fatalError("No UIWindowScene available to present authorization UI.")
        } else {
            // Fallback for < iOS 26 where frame-based initializer is not deprecated
            return UIWindow(frame: UIScreen.main.bounds)
        }
    }
}

// MARK: - Nonce helpers
private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}

private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        var randoms = [UInt8](repeating: 0, count: 16)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
        if errorCode != errSecSuccess { fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)") }
        randoms.forEach { random in
            if remainingLength == 0 { return }
            if random < charset.count { result.append(charset[Int(random)]) ; remainingLength -= 1 }
        }
    }
    return result
}
