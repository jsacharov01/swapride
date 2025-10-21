import SwiftUI

struct AuthView: View {
    @EnvironmentObject var auth: AuthService
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isRegistering: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 16)

            // Brand
            Image(systemName: "car.2").font(.system(size: 48))
            Text("swapride").font(.largeTitle).bold()

            // Mode heading
            VStack(spacing: 6) {
                Text(isRegistering ? "Vytvoř si účet" : "Vítej zpět")
                    .font(.title2).bold()
                Text(isRegistering ? "Zaregistruj se pomocí e‑mailu a hesla" : "Přihlas se pro pokračování")
                    .foregroundStyle(.secondary)
            }

            // Mode segmented control
            Picker("Režim", selection: $isRegistering) {
                Text("Přihlášení").tag(false)
                Text("Registrace").tag(true)
            }
            .pickerStyle(.segmented)

            // Email/Password form
            VStack(spacing: 12) {
                // Email
                TextField("E-mail", text: $email)
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.leading, 36)
                    .padding(.vertical, 12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .leading) {
                        Image(systemName: "envelope")
                            .foregroundStyle(.secondary)
                            .padding(.leading, 12)
                    }

                // Password
                SecureField("Heslo", text: $password)
                    .textContentType(.password)
                    .padding(.leading, 36)
                    .padding(.vertical, 12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .leading) {
                        Image(systemName: "lock")
                            .foregroundStyle(.secondary)
                            .padding(.leading, 12)
                    }

                // Forgot password (only for login)
                if !isRegistering {
                    Button("Obnovit heslo") {
                        Task {
                            do {
                                try await auth.sendPasswordReset(to: email)
                                await MainActor.run { errorMessage = nil }
                            } catch {
                                await MainActor.run { errorMessage = error.localizedDescription }
                            }
                        }
                    }
                    .font(.footnote.weight(.medium))
                    .tint(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .disabled(email.isEmpty)
                }

                if let msg = errorMessage {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Primary action
                Button {
                    Task {
                        do {
                            if isRegistering {
                                try await auth.createUserWithEmail(email: email, password: password)
                            } else {
                                try await auth.signInWithEmail(email: email, password: password)
                            }
                            await MainActor.run { errorMessage = nil }
                        } catch {
                            await MainActor.run { errorMessage = error.localizedDescription }
                        }
                    }
                } label: {
                    Text(isRegistering ? "Vytvořit účet" : "Přihlásit se")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || password.isEmpty)
            }

            // Or divider
            HStack(spacing: 8) {
                Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                Text("nebo").foregroundStyle(.secondary)
                Rectangle().frame(height: 1).foregroundStyle(.quaternary)
            }

            // Google sign-in
            Button {
                if let vc = auth.topViewController() {
                    Task { @MainActor in
                        try? await auth.signInWithGoogle(presenting: vc)
                    }
                }
            } label: {
                Label("Pokračovat s Google", systemImage: "g.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Spacer(minLength: 16)
        }
        .padding()
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
