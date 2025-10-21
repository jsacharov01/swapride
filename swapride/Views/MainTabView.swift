import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            NavigationStack { CreateSituationView() }
                .tabItem { Label("Situace", systemImage: "list.bullet.rectangle.portrait") }
            
            NavigationStack { CarListView() }
                .tabItem { Label("Auta", systemImage: "car.fill") }
            
            NavigationStack { RequestsView() }
                .tabItem { Label("Žádosti", systemImage: "arrow.2.squarepath") }
            
            NavigationStack { ProfileView() }
                .tabItem { Label("Profil", systemImage: "person.crop.circle") }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var auth: AuthService
    var body: some View {
        List {
            Section("Uživatel") {
                HStack {
                    Image(systemName: "person.crop.circle")
                        .font(.largeTitle)
                    VStack(alignment: .leading) {
                        Text(appState.currentUser.displayName)
                            .font(.headline)
                        if let rating = appState.currentUser.rating {
                            Text(String(format: "Hodnocení: %.1f★", rating))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Button(role: .destructive) {
                    auth.signOut()
                } label: {
                    Label("Odhlásit", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
            
            Section("Moje auta") {
                ForEach(appState.carsOfCurrentUser()) { car in
                    NavigationLink(destination: CarDetailView(car: car)) {
                        VStack(alignment: .leading) {
                            Text(car.title).font(.headline)
                            Text("\(car.make) \(car.model), \(car.year) • \(car.seats) míst")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                NavigationLink {
                    CreateListingView()
                } label: {
                    Label("Přidat auto", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Profil")
    }
}
