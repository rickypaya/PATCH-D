import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    //MARK: - App State Variables
    
    @Published var isAuthenticated = false
    @Published var currentUser: CollageUser? //logged in user profile
    @Published var currentUserId: UUID? //logged in user id
    @Published var activeSessions: [CollageSession] = [] //array of active collage sessions for user
    @Published var isLoading = false //Is the app currently loading
    @Published var errorMessage: String? //error message if any present in app state
    @Published var currentState: CurrState = .signUp //current app page
    
    //MARK: - Private properties
    
    private let supabase = SupabaseManager.shared
    private let dbManager = CollageDBManager.shared
    
    private init() {
        Task {
            //on launch, check if a user is logged in.
            await checkAuthStatus()
        }
    }
    
    //MARK: - Authentication
    
    //On app launch, check if user is signed in
    //if so fetch active collage sessions
    func checkAuthStatus() async {
        do {
            let user = try await supabase.getCurrentUser()
            currentUserId = user.id
            
            // fetch full profile
            let profile = try await dbManager.fetchUser(userId: user.id)
            currentUser = profile
            isAuthenticated = true
            
            //load active collage sessions
            await loadActiveSessions()
        }
        catch {
            print("No user authenticated")
            isAuthenticated = false
            currentUser = nil
            currentUserId = nil
            currentState = .signUp
            activeSessions = []
        }
    }
    
    //fetches the active collage sessions for the user
    func loadActiveSessions() async {
        guard let userId = currentUserId else {
            activeSessions = []
            return
        }
        
        isLoading = true
        
        do{
            let sessions = try await dbManager.fetchSessions()
            activeSessions = sessions
        }catch {
            errorMessage = "Failed to load sessions: \(error.localizedDescription)"
            print(errorMessage)
            activeSessions = []
        }
        
        isLoading = false
    }
    
    //refresh function
    func refreshActiveSessions() async {
        await loadActiveSessions()
    }
    
    //handles sign in
    //creates an entry in Supabase Auth table
    //Updates entry in Supabase Users table
    func signUpWithEmail(email: String, password: String, username: String) async throws {
        isLoading = true
        errorMessage = nil
        do {
            //create auth user with supabase auth
            let authResp = try await supabase.signUpWithEmail(email: email, password: password)
            try await dbManager.updateUsername(username: username)
            currentState = .logIn
        } catch {
            errorMessage = error.localizedDescription
            print(errorMessage)
            throw error
        }
        
        isLoading = false
    }
    
    //handles signin with email
    //sets current userId and profile in app state
    //loads active collage sessions
    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            print("In signin func")
            //sign in with supabase
            try await supabase.signIn(email: email, password: password)
            
            //get current user
            let user = try await supabase.getCurrentUser()
            currentUserId = user.id
            
            //fetch user profile
            try await getCurrentUserProfile()
            isAuthenticated = true
            
            //load active sessions
            await loadActiveSessions()
            currentState = .dashboard
        }catch {
            errorMessage = error.localizedDescription
            print(errorMessage)
            throw error
        }
        
        isLoading = false
    }
    
    //handles supabase db signout
    func signOut() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            currentState = .logIn
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
    
    func clearError() {
        errorMessage = nil
    }
    
    //MARK: - Utilities for input format checking
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
    
    //update user avatar
    func updateUserAvatar(_ image: UIImage) {
        guard let userId = currentUserId else {
            errorMessage = "No user logged in"
            return
        }
        
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                let avatarUrl = try await dbManager.uploadUserAvatar(userId: userId, image: image)
                
                // Refresh user profile to get updated avatar URL
                try await refreshUserProfile()
                
                print("Avatar uploaded successfully: \(avatarUrl)")
            } catch {
                errorMessage = "Failed to upload avatar: \(error.localizedDescription)"
                print(errorMessage ?? "")
            }
            
            isLoading = false
        }
        
    }
}
