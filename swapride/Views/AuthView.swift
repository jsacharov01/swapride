import SwiftUI

struct AuthView: View {
    @EnvironmentObject var auth: AuthService
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "car.2" ).font(.system(size: 48))
            Text("swapride").font(.largeTitle).bold()
            Text("Přihlas se pro pokračování")
                .foregroundStyle(.secondary)
            Spacer()
            
            Button {
                auth.startSignInWithAppleFlow()
            } label: {
                Label("Pokračovat s Apple", systemImage: "applelogo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            Button {
                if let vc = auth.topViewController() {
                    Task { try? await auth.signInWithProvider("google.com", presenting: vc) }
                }
            } label: {
                Label("Pokračovat s Google", systemImage: "g.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button {
                if let vc = auth.topViewController() {
                    Task { try? await auth.signInWithProvider("facebook.com", presenting: vc) }
                }
            } label: {
                Label("Pokračovat s Facebook", systemImage: "f.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button {
                if let vc = auth.topViewController() {
                    Task { try? await auth.signInWithProvider("microsoft.com", presenting: vc) }
                }
            } label: {
                Label("Pokračovat s Microsoft", systemImage: "m.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Spacer()
        }
        .padding()
    }
}
