import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    //async loadCurrentUser() -> None
    //async loadCollageSessions() -> None
    //async signUpWithEmail(email, password, username) -> none
    //async signInWithEmail(email, password) -> None
    //async signOut() -> None
    //      clearError() -> None
    //updateUseravatar(image) -> None
    
    
    static let shared = AppState()
    
    //MARK: - App State Variables
    
    @Published var isAuthenticated = false
    @Published var currentUser: CollageUser? //logged in user profile
    @Published var collageSessions: [CollageSession] = [] //array of active collage sessions for user
    @Published var selectedSession: CollageSession?
    @Published var collagePhotos: [CollagePhoto] = []
    @Published var isLoading = false //Is the app currently loading
    @Published var errorMessage: String? //error message if any present in app state
    @Published var currentState: CurrState = .signUp //current app page
    
    private var realTimeTask: Task <Void,Never>?
    
    //MARK: - Private properties
    
    private let dbManager = CollageDBManager.shared
    
    private init() {
        Task {
            await loadCurrentUser()
            await loadCollageSessions()
        }
    }
    
    func loadCurrentUser() async {
        do {
            currentUser = try await dbManager.getCurrentUser()
            print(currentUser)
        } catch {
            errorMessage = "Failed to load user: \(error.localizedDescription)"
        }
    }
    
    func loadCollageSessions() async {
        isLoading = true
        do {
            collageSessions = try await dbManager.fetchSessions()
        } catch {
            errorMessage = "Failed to load collage sessions: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    
    
    //MARK: - Authentication
    
    
    //handles sign in
    //creates an entry in Supabase Auth table
    //Updates entry in Supabase Users table
    func signUpWithEmail(email: String, password: String, username: String) async throws {
        isLoading = true
        errorMessage = nil
        do {
            //create auth user with supabase auth
            let authResp = try await dbManager.signUpWithEmail(email: email, password: password)
            try await dbManager.updateUsername(username: username)
            currentState = .logIn
        } catch {
            errorMessage = error.localizedDescription
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
            try await dbManager.signIn(email: email, password: password)
            
            //fetch user profile
            await loadCurrentUser()
            isAuthenticated = true
            
            //load active sessions
            await loadCollageSessions()
            
            currentState = .dashboard
        }catch {
            errorMessage = error.localizedDescription
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
            try await dbManager.signOut()
            
            //clear state
            isAuthenticated = false
            currentUser = nil
            collageSessions = []
        }catch {
            errorMessage = error.localizedDescription
            throw error
        }
        isLoading = false
    }
    
    
    func clearError() {
        errorMessage = nil
    }
    
    func createNewCollageSession(theme: String, duration: TimeInterval) async {
        isLoading = true
        do {
            
            do {
                // Create collage
                let session = try await dbManager.createCollage(
                    theme: theme,
                    duration: duration
                )
            }catch{
                errorMessage = "Error creating collage: \(error)"
            }
            
        }
    }
    
    func selectCollageSession(_ session: CollageSession) async {
        selectedSession = session
        await loadPhotosForSelectedSession()
        startRealtimeSubscription()
    }
    
    func deselectCollageSession(captureView: UIView?) async {
        if let session = selectedSession, let view = captureView {
            await captureAndUploadPreview(for: session, from: view)
        }
        
        stopRealTimeSubscription()
        selectedSession = nil
        collagePhotos = []
        
        await loadCollageSessions()
        
    }
    
    func loadPhotosForSelectedSession() async {
        guard let session = selectedSession else {return}
        
        do {
            collagePhotos = try await dbManager.fetchPhotosForSession(sessionId: session.id)
        }catch{
            errorMessage = "Error loading photos: \(error)"
        }
    }
    
    private func startRealtimeSubscription() {
        guard let session = selectedSession else {return}
        
        realTimeTask = dbManager.subscribeToPhotoUpdates(sessionId: session.id) { [weak self] updatedPhotos in
            Task { @MainActor in
                self?.collagePhotos = updatedPhotos
            }
        }
    }
    
    private func stopRealTimeSubscription() {
        realTimeTask?.cancel()
        realTimeTask = nil
    }
    
    func captureAndUploadPreview(for session: CollageSession, from view: UIView) async {
           let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
           let image = renderer.image { context in
               view.layer.render(in: context.cgContext)
           }
           
           do {
               _ = try await dbManager.uploadCollagePreview(sessionId: session.id, image: image)
           } catch {
               errorMessage = "Failed to upload preview: \(error.localizedDescription)"
           }
       }
    
    func addPhotoFromPasteboard(at position: CGPoint, in viewSize: CGSize) async {
            guard let session = selectedSession else { return }
            guard UIPasteboard.general.hasImages else { return }
            guard let image = UIPasteboard.general.image else { return }
            
            do {
                // Upload the cutout image
                let imageUrl = try await dbManager.uploadCutoutImage(sessionId: session.id, image: image)
                
                // Calculate normalized position (0-1 range)
                let normalizedX = Double(position.x / viewSize.width)
                let normalizedY = Double(position.y / viewSize.height)
                
                // Add photo to database
                let newPhoto = try await dbManager.addPhotoToCollage(
                    sessionId: session.id,
                    imageURL: imageUrl,
                    positionX: normalizedX,
                    positionY: normalizedY
                )
                
                // Update local state
                collagePhotos.append(newPhoto)
            } catch {
                errorMessage = "Failed to add photo: \(error.localizedDescription)"
            }
        }
        
        func updatePhotoTransform(_ photo: CollagePhoto, position: CGPoint, rotation: Double, scale: Double, in viewSize: CGSize) async {
            // Calculate normalized position
            let normalizedX = Double(position.x / viewSize.width)
            let normalizedY = Double(position.y / viewSize.height)
            
            do {
                try await dbManager.updatePhotoTransform(
                    photoId: photo.id,
                    positionX: normalizedX,
                    positionY: normalizedY,
                    rotation: rotation,
                    scale: scale
                )
                
                // Update local state
                if let index = collagePhotos.firstIndex(where: { $0.id == photo.id }) {
                    collagePhotos[index] = CollagePhoto(
                        id: photo.id,
                        collage_session_id: photo.collage_session_id,
                        user_id: photo.user_id,
                        image_url: photo.image_url,
                        position_x: normalizedX,
                        position_y: normalizedY,
                        roation: rotation,
                        scale: scale,
                        created_at: photo.created_at,
                        updated_at: Date()
                    )
                }
            } catch {
                errorMessage = "Failed to update photo: \(error.localizedDescription)"
            }
        }

    
//    //update user avatar
//    func updateUserAvatar(_ image: UIImage) {
//        print(currentUser)
//        guard let userId = currentUser else {
//            errorMessage = "No user logged in"
//            return
//        }
//        
//        Task {
//            isLoading = true
//            errorMessage = nil
//            
//            do {
////                let avatarUrl = try await dbManager.uploadUserAvatar(userId: userId, image: image)
//                
//                // Refresh user profile to get updated avatar URL
//                await loadCurrentUser()
//                
////                print("Avatar uploaded successfully: \(avatarUrl)")
//            } catch {
//                errorMessage = "Failed to upload avatar: \(error.localizedDescription)"
//                print(errorMessage ?? "")
//            }
//            
//            isLoading = false
//        }
//        
//    }
}
