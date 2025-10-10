import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var currentUserId: UUID? = nil
    @Published var activeSessions: [CollageSession] = []
    @Published var selectedSession: CollageSession? = nil
    @Published var showAuth: Bool = true
    @Published var isCreatingCollage: Bool = false
    @Published var joinCode: String = ""
    
    
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
    
//    // MARK: - Session loading
//    func loadActiveSessions() async {
//        guard let userId = currentUserId else { return }
//        CollageDBManager.shared.fetchActiveSessions(for: userId) { sessions in
//            DispatchQueue.main.async {
//                self.activeSessions = sessions
//            }
//        }
//    }
//    
//    // MARK: - Collage creation
//    func createNewCollage(duration: TimeInterval = 600) async {
//        isCreatingCollage = true
//        do {
//            let theme = try await CollageDBManager.shared.fetchRandomTheme()
//            let newCollage = try await CollageDBManager.shared.createCollage(theme: theme, duration: duration)
//            await loadActiveSessions()
//            selectedSession = newCollage
//        } catch {
//            print("Error creating collage:", error.localizedDescription)
//        }
//        isCreatingCollage = false
//    }
//    
//    // MARK: - Join existing collage
//    func joinCollage(code: String) async {
//        // TODO: Decode invite code → collageId
//        guard let collageId = UUID(uuidString: code) else { return }
//        do {
//            try await CollageDBManager.shared.joinCollage(collageId: collageId)
//            await loadActiveSessions()
//        } catch {
//            print("Error joining collage:", error.localizedDescription)
//        }
//    }
}
