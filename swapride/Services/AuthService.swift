//
//  AuthService.swift
//  swapride
//
//  Created by GitHub Copilot on 19.10.2025.
//

import Foundation
import Combine
import FirebaseAuth
import UIKit

@MainActor
final class AuthService: NSObject, ObservableObject {
    @Published var user: User?
    private var authHandle: AuthStateDidChangeListenerHandle?
    
    override init() {
        super.init()
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.user = user }
        }
    }
    
    deinit {
        if let h = authHandle { Auth.auth().removeStateDidChangeListener(h) }
    }
    
    // MARK: - Google Sign-In (web-based OAuth via Firebase)
    func signInWithGoogle(presenting: UIViewController) async throws {
        let provider = OAuthProvider(providerID: "google.com")
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

    // MARK: - Email/Password
    func signInWithEmail(email: String, password: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(withEmail: email, password: password) { _, error in
                if let error = error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }

    func createUserWithEmail(email: String, password: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            Auth.auth().createUser(withEmail: email, password: password) { _, error in
                if let error = error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }

    func sendPasswordReset(to email: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error { continuation.resume(throwing: error) }
                else { continuation.resume() }
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

// Apple, Microsoft, and Facebook flows removed. Only Google remains.
