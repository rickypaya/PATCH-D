import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    //MARK: - App State Variables
    
    @Published var isAuthenticated = false
    @Published var currentUser: CollageUser?
    @Published var currentUserId: UUID?
    @Published var activeSessions: [CollageSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    //MARK: - Private properties
    
    private let supabase = SupabaseManager.shared
    private let dbManager = CollageDBManager.shared
    
    private init() {
        Task {
            await checkAuthStatus()
        }
    }
    
    //MARK: - Authentication
    
    //On app launch, check if user has an active session
    func checkAuthStatus() async {
        do {
            let user = try await supabase.getCurrentUser()
            currentUserId = user.id
            
            // fetch full profile
            let profile = try await dbManager.fetchUser(userId: user.id)
            currentUser = profile
            isAuthenticated = true
            
            //loada active collage sessions
            await loadActiveSessions()
        }
        catch {
            isAuthenticated = false
            currentUser = nil
            currentUserId = nil
            activeSessions = []
        }
    }
    
    func loadActiveSessions() async {
        guard let userId = currentUserId else {
            activeSessions = []
            return
        }
        
        isLoading = true
        
        do{
            let sessions = try await dbManager.fetchActiveSessions(for: userId)
            activeSessions = sessions
        }catch {
            errorMessage = "Failed to load sessionsL: \(error.localizedDescription)"
            activeSessions = []
        }
        
        isLoading = false
    }
    
    func refreshActiveSessions() async {
        await loadActiveSessions()
    }
    
    func signUpWithEmail(email: String, password: String, username: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            //create auth user with supabase auth
            
            let authResponse = try await supabase.client.auth.signUp(email: email, password: password)
            
            let userId = authResponse.user.id
                    
            // create user profile in colalge_users table
            let profileData = CollageUser(
                id: userId,
                email: email,
                username: username,
                avatarUrl: nil
            )
            
            try await supabase.client.from("collage_users").insert(profileData).execute()
            
            let userProfile: CollageUser = try await supabase.client
                .from("collage_users")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            //update app state
            currentUserId = userId
            currentUser = userProfile
            isAuthenticated = true
            activeSessions = []
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            //sign in with supabase
            try await supabase.signIn(email: email, password: password)
            
            //get current user
            let user = try await supabase.getCurrentUser()
            currentUserId = user.id
            
            //fetch user profile
            let profile = try await dbManager.fetchUser(userId: user.id)
            currentUser = profile
            isAuthenticated = true
            
            
            //load active sessions
            await loadActiveSessions()
        }catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func signOut() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase.signOut()
            
            //clear state
            isAuthenticated = false
            currentUser = nil
            currentUserId = nil
            activeSessions = []
        }catch {
            errorMessage = error.localizedDescription
            throw error
        }
        isLoading = false
    }
    
    //check if user is currently authenticated
    func isUserAuthenticated() -> Bool {
        return isAuthenticated && currentUser != nil && currentUserId != nil
    }
    
    //get current user's profile
    func getCurrentUserProfile() async throws -> CollageUser {
        //return caches profile if availible
        if let user = currentUser {
            return user
        }
        
        //otherwise fetch from database
        guard let userId = currentUserId else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let profile = try await dbManager.fetchUser(userId: userId)
        currentUser = profile
        return profile
    }
    
    //refresh current user profile from db
    func refreshUserProfile() async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let profile = try await dbManager.fetchUser(userId: userId)
        currentUser = profile
    }
    
    
    func addSessions (_ session: CollageSession) {
        //check if session exists
        if !activeSessions.contains(where: { $0.id == session.id }) {
            activeSessions.append(session)
        }
    }
    
    func updateSession(_ session: CollageSession) {
        if let index = activeSessions.firstIndex(where: { $0.id == session.id }) {
            activeSessions[index] = session
        }
    }
    
    func removeSession(sessionId: UUID) {
        activeSessions.removeAll { $0.id == sessionId }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    //validate email format
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    //validate password strength
    func validatePassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    //validate username (3-30 chars, matches DB constraint)
    func validateUserName(_ username: String) -> Bool {
        return username.count >= 3 && username.count <= 30
    }
    
    
}
