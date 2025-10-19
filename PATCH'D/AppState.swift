import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    
    static let shared = AppState()
    
    //MARK: - App State Variables
    
    @Published var currentState: CurrState = .dashboard
    @Published var isAuthenticated = false
    @Published var currentUser: CollageUser?
    @Published var collageMemberships: [UUID] = []
    @Published var activeSessions: [CollageSession] = []
    @Published var archive: [CollageSession] = []
    
    // State for selected collage
    @Published var selectedSession: CollageSession? = nil
    @Published var collagePhotos: [CollagePhoto] = []
    @Published var collageMembers: [CollageUser] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Cache for UI optimization
    private var sessionCache: [UUID: CollageSession] = [:]
    private var photoCache: [UUID: [CollagePhoto]] = [:] // sessionId -> photos
    
    private var realTimeTask: Task<Void, Never>?
    
    //MARK: - Private properties
    
    private let dbManager = CollageDBManager.shared
    
    private init() {
        Task {
            isLoading = true
            await loadCurrentUser()
            await fetchMemberships()
            await loadCollageSessions()
            
            // Auto-cleanup expired collages in background
            autoCleanupExpiredCollages()
            
            currentState = .dashboard
            isLoading = false
        }
    }
    
    func loadCurrentUser() async {
        do {
            currentUser = try await dbManager.getCurrentUser()
            isAuthenticated = true
        } catch {
            errorMessage = "Failed to load user: \(error.localizedDescription)"
            currentState = .signUp
            isAuthenticated = false
        }
    }
    
    func fetchMemberships() async {
        guard let currentUser = currentUser else {
            errorMessage = "No user logged in"
            isLoading = false
            return
        }
        do {
            collageMemberships = try await dbManager.fetchMemberships(userId: currentUser.id)
        } catch {
            errorMessage = "Failed to load user memberships: \(error.localizedDescription)"
        }
    }
    
    // OPTIMIZED: Load both active and expired sessions in one call
    func loadCollageSessions() async {
        guard let currentUser = currentUser else {
            errorMessage = "No user logged in"
            isLoading = false
            return
        }
        
        guard !collageMemberships.isEmpty else {
            activeSessions = []
            archive = []
            return
        }
        
        do {
            let (active, expired) = try await dbManager.fetchAllSessions(
                memberships: collageMemberships,
                user: currentUser
            )
            
            activeSessions = active
            archive = expired
            
            // Cache the sessions
            active.forEach { sessionCache[$0.id] = $0 }
            expired.forEach { sessionCache[$0.id] = $0 }
            
        } catch {
            errorMessage = "Failed to load collage sessions: \(error.localizedDescription)"
        }
    }
    
    // Refresh only active sessions (lighter operation)
    func refreshActiveSessions() async {
        guard let currentUser = currentUser else { return }
        
        do {
            activeSessions = try await dbManager.fetchActiveSessions(
                memberships: collageMemberships,
                user: currentUser
            )
            
            // Update cache
            activeSessions.forEach { sessionCache[$0.id] = $0 }
        } catch {
            errorMessage = "Failed to refresh sessions: \(error.localizedDescription)"
        }
    }
    
    func loadCollageMembersForSession(collage_id: UUID) async {
        do {
            collageMembers = try await dbManager.fetchCollageMembers(collageId: collage_id)
        } catch {
            errorMessage = "Failed to load collage members: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Photo Deletion
    
    func deletePhoto(_ photo: CollagePhoto) async {
        guard selectedSession != nil else { return }
        
        do {
            // Delete from database and storage
            try await dbManager.deletePhoto(photoId: photo.id)
            
            // Update local state immediately for responsive UI
            if let index = collagePhotos.firstIndex(where: { $0.id == photo.id }) {
                collagePhotos.remove(at: index)
            }
            
            // Update cache
            if let sessionId = selectedSession?.id {
                photoCache[sessionId] = collagePhotos
            }
            
        } catch {
            errorMessage = "Failed to delete photo: \(error.localizedDescription)"
            
            // Refresh photos to ensure consistency
            await loadPhotosForSelectedSession()
        }
    }
    
    // Batch delete photos (useful for cleanup)
    func deletePhotos(_ photos: [CollagePhoto]) async {
        guard selectedSession != nil else { return }
        
        await withTaskGroup(of: Void.self) { group in
            for photo in photos {
                group.addTask {
                    do {
                        try await self.dbManager.deletePhoto(photoId: photo.id)
                    } catch {
                        print("Failed to delete photo \(photo.id): \(error)")
                    }
                }
            }
        }
        
        // Refresh photos after batch deletion
        await loadPhotosForSelectedSession()
    }
    
    //MARK: - Authentication
    
    func signUpWithEmail(email: String, password: String, username: String) async throws {
        isLoading = true
        errorMessage = nil
        do {
            let authResp = try await dbManager.signUpWithEmail(email: email, password: password)
            try await dbManager.updateUsername(username: username)
            currentState = .logIn
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
            print("In signin func")
            try await dbManager.signIn(email: email, password: password)
            
            await loadCurrentUser()
            await fetchMemberships()
            isAuthenticated = true
            
            await loadCollageSessions()
            
            currentState = .dashboard
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func signOut() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            currentState = .logIn
            try await dbManager.signOut()
            
            // Clear state and caches
            isAuthenticated = false
            currentUser = nil
            activeSessions = []
            archive = []
            collageMemberships = []
            selectedSession = nil
            collagePhotos = []
            collageMembers = []
            
            // Clear caches
            sessionCache.removeAll()
            photoCache.removeAll()
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func createNewCollageSession(theme: String, duration: TimeInterval, isPartyMode: Bool) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await dbManager.createCollage(
                theme: theme,
                duration: duration,
                isPartyMode: isPartyMode
            )
            
            // Update local state
            activeSessions.append(session)
            collageMemberships.append(session.id)
            
            // Cache the new session
            sessionCache[session.id] = session
            
        } catch {
            errorMessage = "Error creating collage: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func selectCollageSession(_ session: CollageSession) async {
        selectedSession = session
        
        // Load from cache if available
        if let cachedPhotos = photoCache[session.id] {
            collagePhotos = cachedPhotos
        } else {
            await loadPhotosForSelectedSession()
        }
        
        startRealtimeSubscription()
        currentState = .fullscreen
    }
    
    func deselectCollageSession(captureView: UIView?) async {
        if let session = selectedSession, let view = captureView {
            await captureAndUploadPreview(for: session, from: view)
        }
        currentState = .dashboard
        stopRealTimeSubscription()
        selectedSession = nil
        collagePhotos = []
        
    }
    
    func loadPhotosForSelectedSession() async {
        guard let session = selectedSession else { return }
        
        // Check cache first
        if let cachedPhotos = photoCache[session.id] {
            collagePhotos = cachedPhotos
            return
        }
        
        do {
            let photos = try await dbManager.fetchPhotosForSession(sessionId: session.id)
            collagePhotos = photos
            
            // Cache the photos
            photoCache[session.id] = photos
        } catch {
            errorMessage = "Error loading photos: \(error.localizedDescription)"
        }
    }
    
    private func startRealtimeSubscription() {
        guard let session = selectedSession else { return }
        
        realTimeTask = dbManager.subscribeToPhotoUpdates(sessionId: session.id) { [weak self] updatedPhotos in
            Task { @MainActor in
                self?.collagePhotos = updatedPhotos
                
                // Update cache
                if let sessionId = self?.selectedSession?.id {
                    self?.photoCache[sessionId] = updatedPhotos
                }
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
            let imageUrl = try await dbManager.uploadCollagePreview(sessionId: session.id, image: image)
            
            // Update session in cache
            if var cachedSession = sessionCache[session.id] {
                cachedSession.collage.previewUrl = imageUrl
                sessionCache[session.id] = cachedSession
                
                // Update in arrays
                if let index = activeSessions.firstIndex(where: { $0.id == session.id }) {
                    activeSessions[index].collage.previewUrl = imageUrl
                }
            }
        } catch {
            errorMessage = "Failed to upload preview: \(error.localizedDescription)"
        }
    }
    
    func addPhotoFromPasteboard(at position: CGPoint) async {
        guard let session = selectedSession else { return }
        guard UIPasteboard.general.hasImages else { return }
        guard let image = UIPasteboard.general.image else { return }
        
        do {
            let imageUrl = try await dbManager.uploadCutoutImage(sessionId: session.id, image: image)
            if let url = URL(string: imageUrl) {
                await addPhotoToCollage(url, at: position)
            }else{
                errorMessage = "Failed to upload image"
            }
        } catch {
            errorMessage = "Failed to add photo: \(error.localizedDescription)"
        }
    }
    
    func uploadPhotoToStorage(_ image: UIImage) async throws -> String {
        guard let session = selectedSession else { return ""}
        do {
            let url = try await dbManager.uploadCutoutImage(sessionId: session.id, image: image)
            return url
        }catch{
            errorMessage = "Failed to upload photo: \(error.localizedDescription)"
            print(errorMessage ?? "No error message")
        }
        return ""
    }
    
    func addPhotoToCollage(_ imageUrl: URL, at globalPosition: CGPoint) async {
        guard let session = selectedSession else { return }
        
        do {
            
            let newPhoto = try await dbManager.addPhotoToCollage(
                sessionId: session.id,
                imageURL: imageUrl.absoluteString,
                positionX: Double(globalPosition.x),
                positionY: Double(globalPosition.y)
            )
            
            // Update local state
            collagePhotos.append(newPhoto)
            
            // Update cache
            photoCache[session.id] = collagePhotos
        } catch {
            errorMessage = "Failed to add photo: \(error.localizedDescription)"
            print(errorMessage ?? "")
        }
    }
    
    func updatePhotoTransform(_ photo: CollagePhoto, position: CGPoint, rotation: Double, scale: Double) async {
        do {
            try await dbManager.updatePhotoTransform(
                photoId: photo.id,
                positionX: Double(position.x),
                positionY: Double(position.y),
                rotation: rotation,
                scale: scale
            )
            
            // Update local state
            if let index = collagePhotos.firstIndex(where: { $0.id == photo.id }) {
                collagePhotos[index] = CollagePhoto(
                    id: photo.id,
                    collage_id: photo.collage_id,
                    user_id: photo.user_id,
                    image_url: photo.image_url,
                    position_x: Double(position.x),
                    position_y: Double(position.y),
                    rotation: rotation,
                    scale: scale,
                    created_at: photo.created_at,
                    updated_at: Date()
                )
                
                // Update cache
                if let sessionId = selectedSession?.id {
                    photoCache[sessionId] = collagePhotos
                }
            }
        } catch {
            errorMessage = "Failed to update photo: \(error.localizedDescription)"
        }
    }
    
    func fetchRandomTheme() async throws -> String {
        do {
            let theme = try await dbManager.fetchRandomTheme()
            return theme
        } catch {
            errorMessage = "Failed to fetch theme: \(error.localizedDescription)"
            throw error
        }
    }
    
    func updateUserAvatar(_ image: UIImage) {
        Task {
            isLoading = true
            errorMessage = nil
            
            guard let currentId: UUID = currentUser?.id else {
                errorMessage = "Please log in first."
                isLoading = false
                return
            }
            
            do {
                let avatarUrl = try await dbManager.uploadUserAvatar(userId: currentId, image: image)
                
                // Update current user in state
                if var user = currentUser {
                    user.avatarUrl = avatarUrl
                    currentUser = user
                }
                
            } catch {
                errorMessage = "Failed to upload avatar: \(error.localizedDescription)"
                print(errorMessage ?? "")
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Cache Management
    
    func clearCaches() {
        sessionCache.removeAll()
        photoCache.removeAll()
    }
    
    func invalidateSessionCache(for sessionId: UUID) {
        sessionCache.removeValue(forKey: sessionId)
        photoCache.removeValue(forKey: sessionId)
    }
    
    // MARK: - Joining Collages
    
    func joinCollageWithInviteCode(_ inviteCode: String) async {
        guard let currentUser = currentUser else {
            errorMessage = "Please log in first"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await dbManager.joinCollageByInviteCode(
                inviteCode: inviteCode,
                user: currentUser
            )
            
            // Update local state
            if !collageMemberships.contains(session.id) {
                collageMemberships.append(session.id)
            }
            
            if !activeSessions.contains(where: { $0.id == session.id }) {
                activeSessions.append(session)
            }
            
            // Cache the session
            sessionCache[session.id] = session
            
        } catch {
            errorMessage = "Failed to join collage: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Cleanup Operations
    
    /// Manually trigger cleanup for a specific expired collage
    func cleanupExpiredCollage(_ collageId: UUID) async {
        do {
            try await dbManager.cleanupExpiredCollage(collageId: collageId)
            
            // Remove from archive if present
            archive.removeAll { $0.id == collageId }
            
            // Clear from cache
            invalidateSessionCache(for: collageId)
            
            print("Successfully cleaned up collage: \(collageId)")
        } catch {
            errorMessage = "Failed to cleanup collage: \(error.localizedDescription)"
        }
    }
    
    /// Cleanup all expired collages for the current user
    func cleanupUserExpiredCollages() async {
        guard let currentUser = currentUser else {
            errorMessage = "No user logged in"
            return
        }
        
        isLoading = true
        
        do {
            try await dbManager.cleanupExpiredCollagesForUser(userId: currentUser.id)
            
            // Reload archive to reflect cleanup
            await loadCollageSessions()
            
            print("Successfully cleaned up expired collages for user")
        } catch {
            errorMessage = "Failed to cleanup expired collages: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Automatically cleanup expired collages on app launch or session load
    func autoCleanupExpiredCollages() {
        guard let currentUser = currentUser else { return }
        
        Task.detached(priority: .background) {
            try? await self.dbManager.cleanupExpiredCollagesForUser(userId: currentUser.id)
        }
    }
}
