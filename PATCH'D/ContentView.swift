//
//  ContentView.swift
//  PATCH'D
//
//  Created by Ricardo Payares on 10/2/25.
//| Table                  | Purpose                                                          |
//| ---------------------- | ---------------------------------------------------------------- |
//| `users`                | Stores registered user accounts (linked to Supabase Auth).       |
//| `collages`             | Represents a collage session (with theme, start/end time, etc.). |
//| `collage_members`      | Many-to-many relation between users and collages.                |
//| `photos`               | Stores uploaded photos placed within a collage.                  |
//| `themes`               | A pool of random themes fetched when a new collage is created.   |
//| `invites` *(optional)* | Stores shareable invite codes to join a collage.                 |

// Supabase storage buckets for photo uploads
//| Bucket           | Path Example                            | Access                           |
//| ---------------- | --------------------------------------- | -------------------------------- |
//| `collage-photos` | `/collages/{collage_id}/{photo_id}.jpg` | Public read, authenticated write |



import SwiftUI
//import Supabase
import UIKit
import Combine

//MARK: - Models


struct CollagePhoto: Identifiable {
    var id: UUID
    var userId: UUID
    var imageUrl: String
    var position: CGPoint
    var aspectRatio: CGFloat
}

struct CollageSession: Identifiable {
    var id: UUID
    var theme: String
    var startTime: Date
    var endTime: Date
    var createdBy: UUID
    var participants: [UUID]
    var photos: [CollagePhoto]
}

//MARK: - Database Managers

class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient
    
    private init() {
        //TODO: - setup supabase URL and anon key
        client = SupabaseClient(
            supabaseURL: URL(string: "https://SUPABASE_URL")!,
            supabaseKey: "SUPABASE_ANON_KEY"
        )
    }
    
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
}

class CollageDBManager {
    static let shared = CollageDBManager()
    
    private init() {}
    
    func fetchRandomTheme() async throws -> String {
        //fetch a random theme from the "Themes" table in supabase
        let result = try await SupabaseManager.shaed.client
            .database
            .from("themes")
            .select()
            .order("RANDOM()", ascending: true)
            .limit(1)
            .execute()
        
        struct ThemeRow: Decodable {let text: String}
        let rows = try result.decoded(to: [ThemeRow].self)
        return rows.first?.text ?? "Untitled"
    }
    
    // TODO: Create collage
    func createCollage(theme: String, duration: TimeInterval) async throws -> Collage {
        // Insert into Supabase collages table
        let theme = try await fetchRandomTheme()
        let expiresAt = Date().addingTimeInterval(duration)
        
        //inset new collage with the theme
        let resule = try await SupabaseManager.shared.client
            .database
            .from("collages")
            .insert([
                "title": theme,
                "theme": theme,
                "expires_at": expiresAt.iso8601
            ])
            .select()
            .single()
            .execute()
        
        return try result.decoded(to: Collage.self)
    }
    
    // TODO: Join collage
    func joinCollage(collageId: UUID) async throws {
        // Insert into collage_members
        fatalError("Implement join")
    }
    
    // TODO: Fetch collage details
    func fetchCollage(collageId: UUID) async throws -> Collage {
        fatalError("Fetch collage by id")
    }
    
    // TODO: Upload photo
    func uploadPhoto(collageId: UUID, image: UIImage, cropRect: CGRect, position: CGPoint) async throws -> CollagePhoto {
        // 1. Upload to Supabase Storage
        // 2. Insert record into photos table
        fatalError("Implement photo upload")
    }
    
    // TODO: Fetch all active sessions for current user
    func fetchActiveSessions(for userId: UUID, completion: @escaping ([CollageSession]) -> Void) {
        // TODO: Query Supabase "sessions" table where participants contains userId AND endTime > now
    }
    
    // TODO: Add new photo to collage
    func uploadPhoto(sessionId: UUID, photo: CollagePhoto, completion: @escaping (Bool) -> Void) {
        // TODO: Upload image to Supabase Storage
        // TODO: Insert into "photos" table with collageId reference
    }
    
}

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var currentUserId: UUID? = nil
    @Published var activeSessions: [CollageSession] = []
    @Published var selectedSession: CollageSession? = nil
    @Published var showAuth: Bool = true
    @Published var isCreatingCollage: Bool = false
    @Published var joinCode: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Auth
    func signIn(email: String, password: String) async {
        do {
            try await SupabaseManager.shared.signIn(email: email, password: password)
            // TODO: Fetch current user ID from Supabase
            self.currentUserId = UUID() // placeholder
            self.showAuth = false
            await loadActiveSessions()
        } catch {
            print("Error signing in:", error.localizedDescription)
        }
    }
    
    func signOut() async {
        do {
            try await SupabaseManager.shared.signOut()
            self.showAuth = true
            self.activeSessions.removeAll()
        } catch {
            print("Sign-out error:", error.localizedDescription)
        }
    }
    
    // MARK: - Session loading
    func loadActiveSessions() async {
        guard let userId = currentUserId else { return }
        CollageDBManager.shared.fetchActiveSessions(for: userId) { sessions in
            DispatchQueue.main.async {
                self.activeSessions = sessions
            }
        }
    }
    
    // MARK: - Collage creation
    func createNewCollage(duration: TimeInterval = 600) async {
        isCreatingCollage = true
        do {
            let theme = try await CollageDBManager.shared.fetchRandomTheme()
            let newCollage = try await CollageDBManager.shared.createCollage(theme: theme, duration: duration)
            await loadActiveSessions()
            selectedSession = newCollage
        } catch {
            print("Error creating collage:", error.localizedDescription)
        }
        isCreatingCollage = false
    }
    
    // MARK: - Join existing collage
    func joinCollage(code: String) async {
        // TODO: Decode invite code → collageId
        guard let collageId = UUID(uuidString: code) else { return }
        do {
            try await CollageDBManager.shared.joinCollage(collageId: collageId)
            await loadActiveSessions()
        } catch {
            print("Error joining collage:", error.localizedDescription)
        }
    }
}

//MARK: - Login View
struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to PATCH'D")
                .font(.largeTitle.bold())
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Sign In") {
                Task { await appState.signIn(email: email, password: password) }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

//MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            VStack {
                if appState.activeSessions.isEmpty {
                    Text("No active collages yet.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(appState.activeSessions) { session in
                        Button {
                            appState.selectedSession = session
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(session.theme)
                                        .font(.headline)
                                    Text("Expires in \(session.endTime.timeIntervalSinceNow / 60, specifier: "%.0f") min")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                
                HStack {
                    Button("➕ Create Collage") {
                        Task { await appState.createNewCollage() }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("🔗 Join Collage") {
                        withAnimation {
                            appState.joinCode = ""
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Your Collages")
        }
        .sheet(item: $appState.selectedSession) { session in
            CollageView(session: session)
        }
        .sheet(isPresented: Binding(get: { !appState.joinCode.isEmpty }, set: { _ in })) {
            JoinCollageView()
        }
    }
}

//MARK: - Join Collage View
struct JoinCollageView: View {
    @EnvironmentObject var appState: AppState
    @State private var code = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Invite Code")
                .font(.title2)
            
            TextField("Invite Code", text: $code)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button("Join") {
                Task { await appState.joinCollage(code: code) }
                appState.joinCode = ""
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

//MARK: - Collage View
struct CollageView: View {
    let session: CollageSession
    @State private var showCamera = false
    @State private var userPhotos: [CollagePhoto] = []
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                ZStack {
                    ForEach(session.photos) { photo in
                        AsyncImage(url: URL(string: photo.imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .position(photo.position)
                                .blur(radius: shouldBlur(photo: photo) ? 20 : 0)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }
            }
            
            VStack {
                Spacer()
                Button {
                    showCamera = true
                } label: {
                    Label("Add Photo", systemImage: "camera.fill")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding()
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraView { image in
                // TODO: random crop + upload logic
            }
        }
        .navigationTitle(session.theme)
    }
    
    func shouldBlur(photo: CollagePhoto) -> Bool {
        // Blur all photos that aren't this user's before expiry
        let isExpired = Date() > session.endTime
        if isExpired { return false }
        guard let userId = AppState.shared.currentUserId else { return true }
        return photo.userId != userId
    }
}

//MARK: - Camera View
struct CameraView: View {
    var onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Camera Placeholder")
                .font(.headline)
                .padding()
            
            Button("Simulate Capture") {
                let sampleImage = UIImage(systemName: "photo")!
                onCapture(sampleImage)
                dismiss()
            }
        }
    }
}

//MARK: - Main Content Flow Controller
struct ContentView: View {
    @StateObject var appState = AppState.shared
    
    var body: some View {
        Group {
            if appState.showAuth {
                AuthenticationView()
            } else {
                DashboardView()
            }
        }
        .environmentObject(appState)
    }
}

#Preview {
    ContentView()
}
