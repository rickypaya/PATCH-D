import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    
    static let shared = AppState()
    
    //MARK: - App State Variables
    
    @Published var currentState: CurrState = .onboardingTitle
    @Published var previousState: CurrState? = nil
    @Published var isAuthenticated = false
    @Published var currentUser: CollageUser?
    @Published var collageMemberships: [UUID] = []
    @Published var activeSessions: [CollageSession] = []
    @Published var archive: [CollageSession] = []
    
    // State for selected collage
    @Published var selectedSession: CollageSession? = nil
    @Published var collagePhotos: [CollagePhoto] = []
    @Published var collageMembers: [CollageUser] = []
    
    // MARK: - Friendship State
    @Published var friends: [CollageUser] = []
    @Published var pendingFriendRequests: [(friendship: Friendship, user: CollageUser)] = []
    @Published var sentFriendRequests: [Friendship] = []
    @Published var friendshipStatus: [UUID: String] = [:] // userId -> status
    
    // MARK: - Collage Invite State
    @Published var pendingCollageInvites: [(invite: CollageInvite, collage: Collage, sender: CollageUser)] = []
    @Published var sentCollageInvites: [UUID: [(invite: CollageInvite, receiver: CollageUser)]] = [:] // collageId -> invites
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var photoUpdates: [UUID] = []
    
    // MARK: - Cache for UI optimization
    private var sessionCache: [UUID: CollageSession] = [:]
    private var photoCache: [UUID: [CollagePhoto]] = [:] // sessionId -> photos
    private var friendsCache: [CollageUser] = []
    private var friendRequestsCache: [(Friendship, CollageUser)] = []
    private var collageInvitesCache: [(CollageInvite, Collage, CollageUser)] = []
    
    // MARK: - Image Cache for Performance
    private var imageCache: [String: UIImage] = [:] // URL -> UIImage
    private let imageCacheQueue = DispatchQueue(label: "imageCache", attributes: .concurrent)
    
    private var realTimeTask: Task<Void, Never>?
    
    //MARK: - Private properties
    
    private let dbManager = CollageDBManager.shared
    
    private init() {
        // Skip authentication check in preview mode
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            currentState = .onboardingTitle
            return
        }
        #endif
        
        Task {
            isLoading = true
            await loadCurrentUser()
            await fetchMemberships()
            await loadCollageSessions()
            
            // Load social data if authenticated
            if isAuthenticated {
                await loadFriends()
                await loadPendingFriendRequests()
                await loadPendingCollageInvites()
            }
            
            // Auto-cleanup expired collages in background
            autoCleanupExpiredCollages()
            
            // Only go to dashboard if user is authenticated, otherwise start onboarding
            if isAuthenticated {
                currentState = .dashboard
            } else {
                currentState = .onboardingTitle
            }
            isLoading = false
        }
    }
    
    func loadCurrentUser() async {
        do {
            currentUser = try await dbManager.getCurrentUser()
            isAuthenticated = true
        } catch {
            // If user record doesn't exist in custom users table, try to create it
            do {
                let session = try await dbManager.getCurrentSession()
                try await dbManager.createUserRecord(userId: session.user.id, email: session.user.email ?? "")
                currentUser = try await dbManager.getCurrentUser()
                isAuthenticated = true
            } catch {
                errorMessage = "Failed to load user: \(error.localizedDescription)"
                isAuthenticated = false
            }
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
            print("DEBUG: User memberships: \(collageMemberships.map { $0.uuidString })")
            let targetId = UUID(uuidString: "4cd1e93f-1c82-406e-bb47-d8536f2ff671")
            if let targetId = targetId {
                let isMember = collageMemberships.contains(targetId)
                print("DEBUG: Is user member of 'Grad picsss' collage (\(targetId.uuidString)): \(isMember)")
            }
            currentState = .homeScreen
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
            
            print("DEBUG: Raw active sessions count: \(active.count)")
            print("DEBUG: Raw expired sessions count: \(expired.count)")
            
            // Check specifically for the Grad picsss collage
            let targetId = UUID(uuidString: "4cd1e93f-1c82-406e-bb47-d8536f2ff671")
            if let targetId = targetId {
                let inActive = active.contains { $0.id == targetId }
                let inExpired = expired.contains { $0.id == targetId }
                print("DEBUG: 'Grad picsss' collage in active sessions: \(inActive)")
                print("DEBUG: 'Grad picsss' collage in expired sessions: \(inExpired)")
                
                if let foundSession = active.first(where: { $0.id == targetId }) {
                    print("DEBUG: Found 'Grad picsss' session - Theme: \(foundSession.collage.theme)")
                    print("DEBUG: Expires at: \(foundSession.collage.expiresAt)")
                    print("DEBUG: Is expired: \(foundSession.collage.expiresAt < Date())")
                }
            }
            
            // Sort active sessions by creation date (most recent first)
            activeSessions = active.sorted { $0.collage.createdAt > $1.collage.createdAt }
            
            // Sort expired sessions by creation date (most recent first)
            archive = expired.sorted { $0.collage.createdAt > $1.collage.createdAt }
            
            print("DEBUG: Final active sessions count: \(activeSessions.count)")
            print("DEBUG: Final active sessions themes: \(activeSessions.map { $0.collage.theme })")
            
            // Cache the sessions
            activeSessions.forEach { sessionCache[$0.id] = $0 }
            archive.forEach { sessionCache[$0.id] = $0 }
            
        } catch {
            errorMessage = "Failed to load collage sessions: \(error.localizedDescription)"
        }
    }
    
    // Refresh only active sessions (lighter operation)
    func refreshActiveSessions() async {
        guard let currentUser = currentUser else { return }
        
        do {
            let sessions = try await dbManager.fetchActiveSessions(
                memberships: collageMemberships,
                user: currentUser
            )
            
            // Sort active sessions by creation date (most recent first)
            activeSessions = sessions.sorted { $0.collage.createdAt > $1.collage.createdAt }
            
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
            photoUpdates.append(photo.id)
            
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
    
    //MARK: - Navigation Helpers
    
    func navigateTo(_ newState: CurrState) {
        previousState = currentState
        currentState = newState
    }
    
    func navigateBack() {
        if let previous = previousState {
            currentState = previous
            previousState = nil
        } else {
            // Default fallback to home screen
            currentState = .homeScreen
        }
    }
    
    func navigateToHome() {
        previousState = currentState
        currentState = .homeScreen
    }
    
    func navigateToProfile() {
        previousState = currentState
        currentState = .profile
    }
    
    //MARK: - Debug Methods
    
    func testSignUpProcess() async {
        print("🔍 Testing sign up process...")
        
        do {
            // Test database connection
            try await dbManager.testDatabaseConnection()
            
            // Test users table
            try await dbManager.testUsersTable()
            
            print("✅ All database tests passed!")
        } catch {
            print("❌ Database test failed: \(error)")
            errorMessage = "Database connection issue: \(error.localizedDescription)"
        }
    }
    
    //MARK: - Authentication
    
    func signUpWithEmail(email: String, password: String, username: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Step 1: Create Supabase auth user and user record
            _ = try await dbManager.signUpWithEmail(email: email, password: password)
            
            // Step 2: Wait a moment for the user record to be fully created
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Step 3: Update username with retry logic
            var usernameUpdateSuccess = false
            for attempt in 1...3 {
                do {
                    try await dbManager.updateUsername(username: username)
                    usernameUpdateSuccess = true
                    break
                } catch {
                    print("Username update attempt \(attempt) failed: \(error)")
                    if attempt < 3 {
                        // Wait before retry
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    }
                }
            }
            
            if !usernameUpdateSuccess {
                print("Warning: Failed to update username after 3 attempts, but continuing with sign up")
            }
            
            // Step 4: Load the current user to set authentication state
            await loadCurrentUser()
            
            // Step 5: Verify user was successfully loaded
            guard isAuthenticated && currentUser != nil else {
                throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Failed to load user after sign up. Please try logging in manually."])
            }
            
            // Step 6: Navigate to success screen
            currentState = .registrationSuccess
            
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            throw error
        }
        
        isLoading = false
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            print("In signin func")
            _ = try await dbManager.signIn(email: email, password: password)
            
            await loadCurrentUser()
            
            // Check if user was successfully loaded
            guard isAuthenticated && currentUser != nil else {
                throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Failed to load user after sign in"])
            }
            
            await fetchMemberships()
            await loadCollageSessions()
            
            // Load social data
            await loadFriends()
            await loadPendingFriendRequests()
            await loadPendingCollageInvites()
            
            currentState = .homeCollageCarousel
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
            currentState = .onboardingWelcome
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
            
            // Clear social data
            friends = []
            pendingFriendRequests = []
            sentFriendRequests = []
            friendshipStatus = [:]
            pendingCollageInvites = []
            sentCollageInvites = [:]
            
            // Clear caches
            clearCaches()
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func createNewCollageSession(theme: String, duration: TimeInterval, isPartyMode: Bool) async -> CollageSession? {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await dbManager.createCollage(
                theme: theme,
                duration: duration,
                isPartyMode: isPartyMode
            )
            
            // Update local state and maintain sorting (most recent first)
            activeSessions.append(session)
            activeSessions = activeSessions.sorted { $0.collage.createdAt > $1.collage.createdAt }
            collageMemberships.append(session.id)
            
            // Cache the new session
            sessionCache[session.id] = session
            
            isLoading = false
            return session
            
        } catch {
            errorMessage = "Error creating collage: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
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
        // Store session reference before clearing it
        let sessionToCapture = selectedSession
        
        // Navigate immediately for better UX
        currentState = .homeScreen
        stopRealTimeSubscription()
        selectedSession = nil
        collagePhotos = []
        
        // Capture preview in background if view is provided
        if let session = sessionToCapture, let view = captureView {
            Task.detached(priority: .background) {
                await self.captureAndUploadPreview(for: session, from: view)
            }
        }
    }
    
    func captureExpiredSession(captureView: UIView?) async {
        if let session = selectedSession, let view = captureView {
            await captureAndUploadPreview(for: session, from: view)
        }
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        currentState = .final
        stopRealTimeSubscription()
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
                guard let self = self else { return }
                
                // Create a set of current photo IDs for efficient lookup
                let currentPhotoIds = Set(self.collagePhotos.map { $0.id })
                let updatedPhotoIds = Set(updatedPhotos.map { $0.id })
                
                // Handle INSERTS - new photos that weren't in the current list
                let insertedPhotos = updatedPhotos.filter { !currentPhotoIds.contains($0.id) }
                for newPhoto in insertedPhotos {
                    self.collagePhotos.append(newPhoto)
                    print("Real-time: Photo inserted - \(newPhoto.id)")
                }
                
                // Trigger preview update when photos are added
                if !insertedPhotos.isEmpty {
                    self.schedulePreviewUpdate()
                }
                
                // Handle UPDATES - photos that exist in both lists but may have changed
                for updatedPhoto in updatedPhotos {
                    if let index = self.collagePhotos.firstIndex(where: { $0.id == updatedPhoto.id }) {
                        let currentPhoto = self.collagePhotos[index]
                        
                        // Check if any properties have changed
                        if currentPhoto.position_x != updatedPhoto.position_x ||
                           currentPhoto.position_y != updatedPhoto.position_y ||
                           currentPhoto.rotation != updatedPhoto.rotation ||
                           currentPhoto.scale != updatedPhoto.scale {
                            self.collagePhotos[index] = updatedPhoto
                            
                            let position = CGPoint(x: updatedPhoto.position_x, y: updatedPhoto.position_y)
                            
                            await self.updatePhotoTransform(currentPhoto,position: position, rotation: updatedPhoto.rotation, scale: updatedPhoto.scale)
                            
                            print("Real-time: Photo updated - \(updatedPhoto.id)")
                        }
                    }
                }
                
                // Handle DELETES - photos that were in current list but not in updated list
                let deletedPhotoIds = currentPhotoIds.subtracting(updatedPhotoIds)
                if !deletedPhotoIds.isEmpty {
                    self.collagePhotos.removeAll { deletedPhotoIds.contains($0.id) }
                    for deletedId in deletedPhotoIds {
                        print("Real-time: Photo deleted - \(deletedId)")
                    }
                }
                
                // Update cache with latest photos
                if let sessionId = self.selectedSession?.id {
                    self.photoCache[sessionId] = self.collagePhotos
                }
            }
        }
    }
    
    private func stopRealTimeSubscription() {
        realTimeTask?.cancel()
        realTimeTask = nil
        
        // Also cancel any pending preview updates
        previewUpdateTask?.cancel()
        previewUpdateTask = nil
    }
    
    func captureAndUploadPreview(for session: CollageSession, from view: UIView) async {
        // Capture the view asynchronously to avoid blocking the main thread
        let image = await Task.detached(priority: .userInitiated) {
            let renderer = await UIGraphicsImageRenderer(bounds: view.bounds)
            return renderer.image { context in
                view.layer.render(in: context.cgContext)
            }
        }.value
        
        do {
            let imageUrl = try await dbManager.uploadCollagePreview(sessionId: session.id, image: image)
            
            // Update session in cache
            if var cachedSession = sessionCache[session.id] {
                cachedSession.collage.previewUrl = imageUrl
                sessionCache[session.id] = cachedSession
                
                // Update in activeSessions array
                if let index = activeSessions.firstIndex(where: { $0.id == session.id }) {
                    activeSessions[index].collage.previewUrl = imageUrl
                }
                
                // Update in archive array
                if let index = archive.firstIndex(where: { $0.id == session.id }) {
                    archive[index].collage.previewUrl = imageUrl
                }
            }
        } catch {
            errorMessage = "Failed to upload preview: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Preview Update Scheduling
    
    private var previewUpdateTask: Task<Void, Never>?
    
    private func schedulePreviewUpdate() {
        // Cancel any existing preview update task
        previewUpdateTask?.cancel()
        
        // Schedule a new preview update with a 2-second delay
        previewUpdateTask = Task.detached(priority: .background) { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                guard let self = self,
                      let session = self.selectedSession,
                      let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first,
                      let rootView = window.rootViewController?.view else {
                    return
                }
                
                // Capture and upload preview
                Task {
                    await self.captureAndUploadPreview(for: session, from: rootView)
                }
            }
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
        guard let session = selectedSession else { 
            throw NSError(domain: "AppState", code: 400, userInfo: [NSLocalizedDescriptionKey: "No active collage session"])
        }
        
        // Show loading state
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Upload with progress tracking
            let url = try await dbManager.uploadCutoutImage(sessionId: session.id, image: image)
            
            await MainActor.run {
                isLoading = false
            }
            
            return url
        } catch {
            await MainActor.run {
                errorMessage = "Failed to upload photo: \(error.localizedDescription)"
                isLoading = false
            }
            print("Upload error: \(error)")
            throw error
        }
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
                
                photoUpdates.append(photo.id)
                print(photoUpdates)
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
    
    // MARK: - Friendship Functions
    
    /// Load friends list with caching
    func loadFriends(forceRefresh: Bool = false) async {
        // Return cached if available and not forcing refresh
        if !forceRefresh && !friendsCache.isEmpty {
            friends = friendsCache
            return
        }
        
        do {
            let fetchedFriends = try await dbManager.fetchFriends()
            friends = fetchedFriends
            friendsCache = fetchedFriends
        } catch {
            errorMessage = "Failed to load friends: \(error.localizedDescription)"
        }
    }
    
    /// Load pending friend requests received
    func loadPendingFriendRequests(forceRefresh: Bool = false) async {
        // Return cached if available and not forcing refresh
        if !forceRefresh && !friendRequestsCache.isEmpty {
            pendingFriendRequests = friendRequestsCache
            return
        }
        
        do {
            let requests = try await dbManager.fetchPendingFriendRequests()
            pendingFriendRequests = requests
            friendRequestsCache = requests
        } catch {
            errorMessage = "Failed to load friend requests: \(error.localizedDescription)"
        }
    }
    
    /// Load sent friend requests
    func loadSentFriendRequests() async {
        do {
            let requests = try await dbManager.fetchSentRequests()
            sentFriendRequests = requests
        } catch {
            errorMessage = "Failed to load sent requests: \(error.localizedDescription)"
        }
    }
    
    /// Send a friend request
    func sendFriendRequest(to userId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await dbManager.sendFriendRequest(to: userId)
            
            // Update friendship status cache
            friendshipStatus[userId] = "pending"
            
            // Refresh sent requests
            await loadSentFriendRequests()
            
        } catch {
            errorMessage = "Failed to send friend request: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Accept a friend request
    func acceptFriendRequest(_ friendshipId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await dbManager.acceptFriendRequest(friendshipId: friendshipId)
            
            // Remove from pending requests
            if let index = pendingFriendRequests.firstIndex(where: { $0.friendship.id == friendshipId }) {
                let acceptedUserId = pendingFriendRequests[index].user.id
                friendshipStatus[acceptedUserId] = "accepted"
                pendingFriendRequests.remove(at: index)
            }
            
            // Refresh friends list and cache
            await loadFriends(forceRefresh: true)
            
            // Clear request cache
            friendRequestsCache = pendingFriendRequests
            
        } catch {
            errorMessage = "Failed to accept friend request: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Reject a friend request
    func rejectFriendRequest(_ friendshipId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await dbManager.rejectFriendRequest(friendshipId: friendshipId)
            
            // Remove from pending requests
            if let index = pendingFriendRequests.firstIndex(where: { $0.friendship.id == friendshipId }) {
                let rejectedUserId = pendingFriendRequests[index].user.id
                friendshipStatus[rejectedUserId] = "rejected"
                pendingFriendRequests.remove(at: index)
            }
            
            // Clear request cache
            friendRequestsCache = pendingFriendRequests
            
        } catch {
            errorMessage = "Failed to reject friend request: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Remove/unfriend a user
    func removeFriend(_ friendshipId: UUID, userId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await dbManager.removeFriendship(friendshipId: friendshipId)
            
            // Remove from friends list
            friends.removeAll { $0.id == userId }
            
            // Update caches
            friendsCache = friends
            friendshipStatus.removeValue(forKey: userId)
            
        } catch {
            errorMessage = "Failed to remove friend: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Check friendship status with a specific user
    func checkFriendshipStatus(with userId: UUID) async -> String? {
        // Check cache first
        if let status = friendshipStatus[userId] {
            return status
        }
        
        do {
            let status = try await dbManager.checkFriendshipStatus(with: userId)
            
            // Cache the result
            if let status = status {
                friendshipStatus[userId] = status
            }
            
            return status
        } catch {
            print("Failed to check friendship status: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Collage Invite Functions
    
    /// Load pending collage invites with caching
    func loadPendingCollageInvites(forceRefresh: Bool = false) async {
        // Return cached if available and not forcing refresh
        if !forceRefresh && !collageInvitesCache.isEmpty {
            pendingCollageInvites = collageInvitesCache
            return
        }
        
        do {
            let invites = try await dbManager.fetchPendingCollageInvites()
            pendingCollageInvites = invites
            collageInvitesCache = invites
        } catch {
            errorMessage = "Failed to load collage invites: \(error.localizedDescription)"
        }
    }
    
    /// Load sent invites for a specific collage
    func loadSentCollageInvites(for collageId: UUID) async {
        do {
            let invites = try await dbManager.fetchSentCollageInvites(collageId: collageId)
            sentCollageInvites[collageId] = invites
        } catch {
            errorMessage = "Failed to load sent invites: \(error.localizedDescription)"
        }
    }
    
    /// Send a collage invite to a friend
    func sendCollageInvite(collageId: UUID, to userId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await dbManager.sendCollageInvite(collageId: collageId, to: userId)
            
            // Refresh sent invites for this collage
            await loadSentCollageInvites(for: collageId)
            
        } catch {
            errorMessage = "Failed to send collage invite: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Send collage invites to multiple friends
    func sendCollageInvitesToMultipleFriends(collageId: UUID, friendIds: [UUID]) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await dbManager.sendCollageInvitesToFriends(collageId: collageId, friendIds: friendIds)
            
            // Refresh sent invites for this collage
            await loadSentCollageInvites(for: collageId)
            
        } catch {
            errorMessage = "Failed to send collage invites: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Accept a collage invite
    func acceptCollageInvite(_ inviteId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await dbManager.acceptCollageInvite(inviteId: inviteId)
            
            // Remove from pending invites
            pendingCollageInvites.removeAll { $0.invite.id == inviteId }
            collageInvitesCache = pendingCollageInvites
            
            // Add to memberships and active sessions
            if !collageMemberships.contains(session.id) {
                collageMemberships.append(session.id)
            }
            
            if !activeSessions.contains(where: { $0.id == session.id }) {
                activeSessions.append(session)
                // Maintain sorting (most recent first)
                activeSessions = activeSessions.sorted { $0.collage.createdAt > $1.collage.createdAt }
            }
            
            // Cache the session
            sessionCache[session.id] = session
            
        } catch {
            errorMessage = "Failed to accept collage invite: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Reject a collage invite
    func rejectCollageInvite(_ inviteId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await dbManager.rejectCollageInvite(inviteId: inviteId)
            
            // Remove from pending invites
            pendingCollageInvites.removeAll { $0.invite.id == inviteId }
            collageInvitesCache = pendingCollageInvites
            
        } catch {
            errorMessage = "Failed to reject collage invite: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Delete a sent collage invite
    func deleteCollageInvite(_ inviteId: UUID, collageId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await dbManager.deleteCollageInvite(inviteId: inviteId)
            
            // Remove from sent invites
            if var invites = sentCollageInvites[collageId] {
                invites.removeAll { $0.invite.id == inviteId }
                sentCollageInvites[collageId] = invites
            }
            
        } catch {
            errorMessage = "Failed to delete invite: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Get friends who haven't been invited to a specific collage
    func getUninvitedFriends(for collageId: UUID) async -> [CollageUser] {
        // Ensure we have the latest sent invites
        await loadSentCollageInvites(for: collageId)
        
        guard let sentInvites = sentCollageInvites[collageId] else {
            return friends
        }
        
        let invitedUserIds = Set(sentInvites.map { $0.receiver.id })
        
        // Also exclude current members
        let memberIds = Set(collageMembers.map { $0.id })
        
        return friends.filter { friend in
            !invitedUserIds.contains(friend.id) && !memberIds.contains(friend.id)
        }
    }
    
    // MARK: - Cache Management
    
    func clearCaches() {
        sessionCache.removeAll()
        photoCache.removeAll()
        friendsCache.removeAll()
        friendRequestsCache.removeAll()
        collageInvitesCache.removeAll()
        clearImageCache()
    }
    
    // MARK: - Image Caching Methods
    
    func getCachedImage(for url: String) -> UIImage? {
        return imageCacheQueue.sync {
            return imageCache[url]
        }
    }
    
        func cacheImage(_ image: UIImage, for url: String) {
            imageCacheQueue.async(flags: .barrier) { [weak self] in
                self?.imageCache[url] = image
            }
        }
    
    func loadImageAsync(from url: String) async -> UIImage? {
        // Check cache first
        if let cachedImage = getCachedImage(for: url) {
            return cachedImage
        }
        
        // Load from network
        guard let imageURL = URL(string: url) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            guard let image = UIImage(data: data) else { return nil }
            
            // Cache the image
            cacheImage(image, for: url)
            return image
        } catch {
            print("Failed to load image from \(url): \(error)")
            return nil
        }
    }
    
        func clearImageCache() {
            imageCacheQueue.async(flags: .barrier) { [weak self] in
                self?.imageCache.removeAll()
            }
        }
    
    func invalidateSessionCache(for sessionId: UUID) {
        sessionCache.removeValue(forKey: sessionId)
        photoCache.removeValue(forKey: sessionId)
    }
    
    func invalidateSocialCaches() {
        friendsCache.removeAll()
        friendRequestsCache.removeAll()
        collageInvitesCache.removeAll()
        friendshipStatus.removeAll()
    }
    
    /// Refresh all social data
    func refreshSocialData() async {
        await loadFriends(forceRefresh: true)
        await loadPendingFriendRequests(forceRefresh: true)
        await loadPendingCollageInvites(forceRefresh: true)
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
                // Maintain sorting (most recent first)
                activeSessions = activeSessions.sorted { $0.collage.createdAt > $1.collage.createdAt }
            }
            
            // Cache the session
            sessionCache[session.id] = session
            
            // Navigate to the collage fullscreen
            await selectCollageSession(session)
            
        } catch {
            if error.localizedDescription.contains("Invalid invite code") {
                errorMessage = "Enter a valid invite code."
            } else {
                errorMessage = "Failed to join collage: \(error.localizedDescription)"
            }
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
    
    // MARK: - Convenience Computed Properties
    
    /// Number of pending friend requests
    var pendingFriendRequestCount: Int {
        pendingFriendRequests.count
    }
    
    /// Number of pending collage invites
    var pendingCollageInviteCount: Int {
        pendingCollageInvites.count
    }
    
    /// Total pending notifications (friend requests + collage invites)
    var totalPendingNotifications: Int {
        pendingFriendRequestCount + pendingCollageInviteCount
    }
    
    /// Check if a user is a friend
    func isFriend(_ userId: UUID) -> Bool {
        friends.contains { $0.id == userId }
    }
    
    /// Check if there's a pending friend request from a user
    func hasPendingFriendRequest(from userId: UUID) -> Bool {
        pendingFriendRequests.contains { $0.user.id == userId }
    }
    
    /// Check if there's a pending collage invite for a specific collage
    func hasPendingCollageInvite(for collageId: UUID) -> Bool {
        pendingCollageInvites.contains { $0.collage.id == collageId }
    }
    
    /// Get friendship ID for a specific user (useful for removing friends)
    func getFriendshipId(for userId: UUID) async -> UUID? {
        do {
            let friendships = try await dbManager.fetchFriendships(status: "accepted")
            
            let friendship = friendships.first { friendship in
                friendship.friendId == userId ||
                (friendship.userId == currentUser?.id && friendship.friendId == userId) ||
                (friendship.friendId == currentUser?.id && friendship.userId == userId)
            }
            
            return friendship?.id
        } catch {
            print("Failed to get friendship ID: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Search Functions
    
    /// Search friends by username
    func searchFriends(query: String) -> [CollageUser] {
        guard !query.isEmpty else { return friends }
        
        let lowercasedQuery = query.lowercased()
        return friends.filter { friend in
            friend.username.lowercased().contains(lowercasedQuery)
        }
    }
    
    /// Search pending friend requests by username
    func searchPendingRequests(query: String) -> [(friendship: Friendship, user: CollageUser)] {
        guard !query.isEmpty else { return pendingFriendRequests }
        
        let lowercasedQuery = query.lowercased()
        return pendingFriendRequests.filter { request in
            request.user.username.lowercased().contains(lowercasedQuery)
        }
    }
    
    // MARK: - Batch Operations
    
    /// Accept multiple friend requests at once
    func acceptMultipleFriendRequests(_ friendshipIds: [UUID]) async {
        isLoading = true
        errorMessage = nil
        
        await withTaskGroup(of: Void.self) { group in
            for friendshipId in friendshipIds {
                group.addTask {
                    do {
                        try await self.dbManager.acceptFriendRequest(friendshipId: friendshipId)
                    } catch {
                        print("Failed to accept request \(friendshipId): \(error)")
                    }
                }
            }
        }
        
        // Refresh social data after batch operation
        await refreshSocialData()
        
        isLoading = false
    }
    
    /// Reject multiple friend requests at once
    func rejectMultipleFriendRequests(_ friendshipIds: [UUID]) async {
        isLoading = true
        errorMessage = nil
        
        await withTaskGroup(of: Void.self) { group in
            for friendshipId in friendshipIds {
                group.addTask {
                    do {
                        try await self.dbManager.rejectFriendRequest(friendshipId: friendshipId)
                    } catch {
                        print("Failed to reject request \(friendshipId): \(error)")
                    }
                }
            }
        }
        
        // Refresh pending requests
        await loadPendingFriendRequests(forceRefresh: true)
        
        isLoading = false
    }
    
    /// Accept multiple collage invites at once
    func acceptMultipleCollageInvites(_ inviteIds: [UUID]) async {
        isLoading = true
        errorMessage = nil
        
        for inviteId in inviteIds {
            do {
                let session = try await dbManager.acceptCollageInvite(inviteId: inviteId)
                
                // Add to memberships and active sessions
                if !collageMemberships.contains(session.id) {
                    collageMemberships.append(session.id)
                }
                
                if !activeSessions.contains(where: { $0.id == session.id }) {
                    activeSessions.append(session)
                }
                
                // Cache the session
                sessionCache[session.id] = session
                
            } catch {
                print("Failed to accept invite \(inviteId): \(error)")
            }
        }
        
        // Sort active sessions after adding multiple invites (most recent first)
        activeSessions = activeSessions.sorted { $0.collage.createdAt > $1.collage.createdAt }
        
        // Refresh collage invites
        await loadPendingCollageInvites(forceRefresh: true)
        
        isLoading = false
    }
    
    // MARK: - User Search Functions

    /// Search for users by username or email
    func searchUsers(query: String) async throws -> [CollageUser] {
        guard let currentUser = currentUser else {
            throw NSError(domain: "AppState", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        guard !query.isEmpty else {
            return []
        }
        
        do {
            let results = try await dbManager.searchUsers(query: query, limit: 20)
            
            // Filter out current user from results
            let filteredResults = results.filter { $0.id != currentUser.id }
            
            return filteredResults
        } catch {
            errorMessage = "Failed to search users: \(error.localizedDescription)"
            throw error
        }
    }

    /// Search for a user by exact username
    func searchUserByUsername(_ username: String) async throws -> CollageUser? {
        do {
            let user = try await dbManager.searchUserByUsername(username: username)
            
            // Don't return current user
            if user?.id == currentUser?.id {
                return nil
            }
            
            return user
        } catch {
            errorMessage = "Failed to search user: \(error.localizedDescription)"
            throw error
        }
    }

    /// Search for a user by exact email
    func searchUserByEmail(_ email: String) async throws -> CollageUser? {
        do {
            let user = try await dbManager.searchUserByEmail(email: email)
            
            // Don't return current user
            if user?.id == currentUser?.id {
                return nil
            }
            
            return user
        } catch {
            errorMessage = "Failed to search user: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Download Functions

    /// Download the collage preview to Photos library
    func downloadCollagePreview(session: CollageSession) async throws {
        guard let previewUrl = session.collage.previewUrl, !previewUrl.isEmpty else {
            throw NSError(domain: "AppState", code: 404, userInfo: [NSLocalizedDescriptionKey: "No preview image available for this collage"])
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await dbManager.downloadCollagePreview(sessionId: session.id)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to download collage: \(error.localizedDescription)"
            throw error
        }
    }

    /// Download any image URL to Photos library
    func downloadImage(from urlString: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await dbManager.downloadImage(from: urlString)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to download image: \(error.localizedDescription)"
            throw error
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension AppState {
    static func preview() -> AppState {
        let state = AppState()
        state.isAuthenticated = true
        state.currentUser = CollageUser(
            id: UUID(),
            email: "preview@example.com",
            username: "previewuser",
            avatarUrl: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        state.friends = [
            CollageUser(
                id: UUID(),
                email: "friend1@example.com",
                username: "friend1",
                avatarUrl: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            CollageUser(
                id: UUID(),
                email: "friend2@example.com",
                username: "friend2",
                avatarUrl: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        return state
    }
}
#endif
