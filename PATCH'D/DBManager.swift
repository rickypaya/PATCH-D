//
//  DBManager.swift
//  PATCH'D
//
import SwiftUI
import Supabase

//MARK: - Collage DB Manager

class CollageDBManager {
    
    static let shared = CollageDBManager()
    private let supabase: SupabaseClient
    
    // MARK: - Cache for reducing redundant calls
    private var userCache: [UUID: CollageUser] = [:]
    private var membershipCache: [UUID: [UUID]] = [:] // userId -> [collageIds]
    
    private init() {
        supabase = SupabaseClient(
            supabaseURL: URL(string: "https://bxrnvixgpktkuwqncafe.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4cm52aXhncGt0a3V3cW5jYWZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4ODU3NzEsImV4cCI6MjA3NTQ2MTc3MX0.hgluiRmwCUruyXvDrEwzDhtZ4zA2QdmClAt8GupIJgs"
        )
    }
    
    func getCurrentUser() async throws -> CollageUser {
        let session = try await supabase.auth.session
        let userId = session.user.id
        
        // Check cache first
        if let cachedUser = userCache[userId] {
            return cachedUser
        }
        
        let response: CollageUser = try await supabase
            .from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        // Cache the user
        userCache[userId] = response
        return response
    }
    
    func signUpWithEmail(email: String, password: String) async throws -> AuthResponse {
        let authResp = try await supabase.auth.signUp(email: email, password: password)
        return authResp
    }
    
    func signIn(email: String, password: String) async throws -> Session {
        let authResp = try await supabase.auth.signIn(email: email, password: password)
        return authResp
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        // Clear cache on sign out
        clearCache()
    }
    
    func clearCache() {
        userCache.removeAll()
        membershipCache.removeAll()
    }
    
    //MARK: - Theme Functions
    
    func fetchRandomTheme() async throws -> String {
        let response: [Theme] = try await supabase
            .from("themes")
            .select()
            .eq("is_active", value: true)
            .execute()
            .value
        
        guard !response.isEmpty else {
            throw NSError(domain: "DB", code: 404, userInfo: [NSLocalizedDescriptionKey: "No active themes found"])
        }
        
        return response.randomElement()?.text ?? response[0].text
    }
    
    //MARK: - Collage Functions
    
    func createCollage(theme: String, duration: TimeInterval, isPartyMode: Bool) async throws -> CollageSession {
        let user = try await getCurrentUser()
        let inviteCode = generateInviteCode()
        let now = Date()
        let expiresAt = now.addingTimeInterval(duration)
        
        struct CollageInsert: Encodable {
            let theme: String
            let created_by: String
            let invite_code: String
            let starts_at: String
            let expires_at: String
            let updated_at: String
            let background_url: String
            let is_party_mode: Bool
        }
        
        let collageData = CollageInsert(
            theme: theme,
            created_by: user.id.uuidString,
            invite_code: inviteCode,
            starts_at: ISO8601DateFormatter().string(from: now),
            expires_at: ISO8601DateFormatter().string(from: expiresAt),
            updated_at: ISO8601DateFormatter().string(from: now),
            background_url: "",
            is_party_mode: isPartyMode
        )
        
        
        let collage: Collage = try await supabase
            .from("collages")
            .insert(collageData)
            .select()
            .single()
            .execute()
            .value
        
        try await joinCollage(collageId: collage.id)
        
        // Invalidate membership cache
        membershipCache.removeValue(forKey: user.id)
        
        let creator = try await fetchUser(userId: user.id)
        let members = try await fetchCollageMembers(collageId: collage.id)
        
        return CollageSession(
            id: collage.id,
            collage: collage,
            creator: creator,
            members: members,
            photos: []
        )
    }
    
    func updateCollagesessionsPreview(sessionId: UUID, imageURL: String) async throws {
        try await supabase
            .from("collages")
            .update([
                "preview_url": imageURL,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: sessionId.uuidString)
            .execute()
    }
    
    func fetchPhotosForSession(sessionId: UUID) async throws -> [CollagePhoto] {
        let response: [CollagePhoto] = try await supabase
            .from("photos")
            .select()
            .eq("collage_id", value: sessionId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    func addPhotoToCollage(sessionId: UUID, imageURL: String, positionX: Double, positionY: Double) async throws -> CollagePhoto {
        let user = try await getCurrentUser()
        
        struct collagePhotoInsert: Encodable {
            let collage_id: UUID
            let user_id: UUID
            let image_url: String
            let position_x: Double
            let position_y: Double
            let rotation: Double
            let scale: Double
            let updated_at: String
            let created_at: String
        }
        
        let newPhoto = collagePhotoInsert(
            collage_id: sessionId,
            user_id: user.id,
            image_url: imageURL,
            position_x: positionX,
            position_y: positionY,
            rotation: 0.0,
            scale: 1.0,
            updated_at: ISO8601DateFormatter().string(from: Date()),
            created_at: ISO8601DateFormatter().string(from: Date())
        )
        
        let response: CollagePhoto = try await supabase
            .from("photos")
            .insert(newPhoto)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func updatePhotoTransform(photoId: UUID, positionX: Double, positionY: Double, rotation: Double, scale: Double) async throws {
        struct PhotoTransformUpdate: Encodable {
            let position_x: Double
            let position_y: Double
            let rotation: Double
            let scale: Double
            let updated_at: String
        }
        
        let updateData = PhotoTransformUpdate(
            position_x: positionX,
            position_y: positionY,
            rotation: rotation,
            scale: scale,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase
            .from("photos")
            .update(updateData)
            .eq("id", value: photoId.uuidString)
            .execute()
    }
    
    // MARK: - Photo Deletion
    
    func deletePhoto(photoId: UUID) async throws {
        // First, get the photo to retrieve the image URL
        let photo: CollagePhoto = try await supabase
            .from("photos")
            .select()
            .eq("id", value: photoId.uuidString)
            .single()
            .execute()
            .value
        
        // Delete from database
        try await supabase
            .from("photos")
            .delete()
            .eq("id", value: photoId.uuidString)
            .execute()
        
        // Delete from storage (extract path from URL)
        if let url = URL(string: photo.image_url),
           let path = extractStoragePath(from: url) {
            try? await deleteImageFromStorage(path: path)
        }
    }
    
    private func deleteImageFromStorage(path: String) async throws {
        try await supabase.storage
            .from("patchd-storage")
            .remove(paths: [path])
    }
    
    private func extractStoragePath(from url: URL) -> String? {
        // Extract path after "patchd-storage/"
        let components = url.pathComponents
        if let storageIndex = components.firstIndex(of: "patchd-storage") {
            let pathComponents = components.suffix(from: storageIndex + 1)
            return pathComponents.joined(separator: "/")
        }
        return nil
    }
    
    // MARK: - Collage Cleanup
    
    /// Deletes all photos associated with an expired collage
    func cleanupExpiredCollage(collageId: UUID) async throws {
        // Verify the collage is expired
        let collage: Collage = try await supabase
            .from("collages")
            .select()
            .eq("id", value: collageId.uuidString)
            .single()
            .execute()
            .value
        
        guard collage.expiresAt < Date() else {
            throw NSError(domain: "DBManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Cannot cleanup active collage"])
        }
        
        // Fetch all photos for this collage
        let photos: [CollagePhoto] = try await supabase
            .from("photos")
            .select()
            .eq("collage_id", value: collageId.uuidString)
            .execute()
            .value
        
        guard !photos.isEmpty else {
            print("No photos to cleanup for collage: \(collageId)")
            return
        }
        
        print("Cleaning up \(photos.count) photos for expired collage: \(collageId)")
        
        // Delete all photos from storage concurrently
        await withTaskGroup(of: Void.self) { group in
            for photo in photos {
                group.addTask {
                    if let url = URL(string: photo.image_url),
                       let path = self.extractStoragePath(from: url) {
                        try? await self.deleteImageFromStorage(path: path)
                    }
                }
            }
        }
        
        // Delete all photo records from database
        try await supabase
            .from("photos")
            .delete()
            .eq("collage_id", value: collageId.uuidString)
            .execute()
        
        print("Successfully cleaned up collage: \(collageId)")
    }
    
    /// Automatically finds and cleans up all expired collages
    func cleanupAllExpiredCollages() async throws {
        let now = ISO8601DateFormatter().string(from: Date())
        
        // Find all expired collages
        let expiredCollages: [Collage] = try await supabase
            .from("collages")
            .select()
            .lt("expires_at", value: now)
            .execute()
            .value
        
        guard !expiredCollages.isEmpty else {
            print("No expired collages to cleanup")
            return
        }
        
        print("Found \(expiredCollages.count) expired collages to cleanup")
        
        // Cleanup each expired collage
        var successCount = 0
        var failureCount = 0
        
        for collage in expiredCollages {
            do {
                try await cleanupExpiredCollage(collageId: collage.id)
                successCount += 1
            } catch {
                print("Failed to cleanup collage \(collage.id): \(error)")
                failureCount += 1
            }
        }
        
        print("Cleanup complete: \(successCount) successful, \(failureCount) failed")
    }
    
    /// Cleans up expired collages for a specific user's memberships
    func cleanupExpiredCollagesForUser(userId: UUID) async throws {
        // Get user's memberships
        let memberships = try await fetchMemberships(userId: userId)
        
        guard !memberships.isEmpty else {
            print("No memberships found for user: \(userId)")
            return
        }
        
        let now = ISO8601DateFormatter().string(from: Date())
        
        // Find expired collages from user's memberships
        let expiredCollages: [Collage] = try await supabase
            .from("collages")
            .select()
            .in("id", values: memberships.map { $0.uuidString })
            .lt("expires_at", value: now)
            .execute()
            .value
        
        guard !expiredCollages.isEmpty else {
            print("No expired collages to cleanup for user: \(userId)")
            return
        }
        
        print("Found \(expiredCollages.count) expired collages for user \(userId)")
        
        // Cleanup each expired collage
        for collage in expiredCollages {
            do {
                try await cleanupExpiredCollage(collageId: collage.id)
            } catch {
                print("Failed to cleanup collage \(collage.id): \(error)")
            }
        }
    }
    
    func uploadImage(_ image: UIImage, bucket: String, folder: String, fileName: String) async throws -> String {
        guard let imageData = image.pngData() else {
            throw NSError(domain: "DBManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let filePath = "\(folder)/\(fileName)"
        
        try await supabase.storage
            .from(bucket)
            .upload(path: filePath, file: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))
        
        let publicURL = try supabase.storage
            .from(bucket)
            .getPublicURL(path: filePath)
        
        return publicURL.absoluteString
    }
    
    func uploadCollagePreview(sessionId: UUID, image: UIImage) async throws -> String {
        let fileName = "\(sessionId.uuidString).png"
        let imageUrl = try await uploadImage(image, bucket: "patchd-storage", folder: "collage-previews", fileName: fileName)
        
        try await updateCollagesessionsPreview(sessionId: sessionId, imageURL: imageUrl)
        
        return imageUrl
    }
    
    //MARK: - Realtime subscriptions
    func subscribeToPhotoUpdates(sessionId: UUID, onChange: @escaping ([CollagePhoto]) -> Void) -> Task<Void, Never> {
        return Task {
            var channel = supabase.channel("photos")
                  
            let changes = channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "photos",
                filter: .eq("collage_id", value: "\(sessionId.uuidString)")
            )
            
            await channel.subscribe()
            
            for await _ in changes {
                do {
                    let photos = try await self.fetchPhotosForSession(sessionId: sessionId)
                    onChange(photos)
                } catch {
                    print("Error fetching updated photos: \(error)")
                }
            }
        }
    }
    
    func uploadCutoutImage(sessionId: UUID, image: UIImage) async throws -> String {
        let fileName = "\(UUID().uuidString).png"
        return try await uploadImage(image, bucket: "patchd-storage", folder: "collage-photos", fileName: fileName)
    }
    
    //MARK: - Avatar Functions

    func uploadUserAvatar(userId: UUID, image: UIImage) async throws -> String {
        guard let imageData = image.pngData() else {
            throw NSError(domain: "DB", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let filename = "\(userId.uuidString)_\(Date().timeIntervalSince1970).png"
        let filePath = "avatars/\(filename)"
        
        try await supabase.storage
            .from("patchd-storage")
            .upload(path: filePath, file: imageData, options: FileOptions(contentType: "image/png"))
        
        let publicURL = try supabase.storage
            .from("patchd-storage")
            .getPublicURL(path: filePath)
        
        struct AvatarUpdate: Encodable {
            let avatar_url: String
            let updated_at: String
        }
        
        let updateData = AvatarUpdate(
            avatar_url: publicURL.absoluteString,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase
            .from("users")
            .update(updateData)
            .eq("id", value: userId.uuidString)
            .execute()
        
        // Update cache
        if var cachedUser = userCache[userId] {
            cachedUser.avatarUrl = publicURL.absoluteString
            userCache[userId] = cachedUser
        }
        
        return publicURL.absoluteString
    }
    
    func joinCollage(collageId: UUID) async throws {
        let user = try await getCurrentUser()
        
        let existingMembers: [CollageMember] = try await supabase
            .from("collage_members")
            .select()
            .eq("collage_id", value: collageId.uuidString)
            .eq("user_id", value: user.id.uuidString)
            .execute()
            .value
        
        guard existingMembers.isEmpty else {
            return
        }
        
        struct MemberInsert: Encodable {
            let collage_id: String
            let user_id: String
        }
        
        let memberData = MemberInsert(
            collage_id: collageId.uuidString,
            user_id: user.id.uuidString
        )
        
        let _: CollageMember = try await supabase
            .from("collage_members")
            .insert(memberData)
            .select()
            .single()
            .execute()
            .value
        
        // Invalidate membership cache
        membershipCache.removeValue(forKey: user.id)
    }
    
    func joinCollageByInviteCode(inviteCode: String, user: CollageUser) async throws -> CollageSession {
        let collages: [Collage] = try await supabase
            .from("collages")
            .select()
            .eq("invite_code", value: inviteCode)
            .execute()
            .value
        
        guard let collage = collages.first else {
            throw NSError(domain: "DB", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invalid invite code"])
        }
        
        guard collage.expiresAt > Date() else {
            throw NSError(domain: "DB", code: 410, userInfo: [NSLocalizedDescriptionKey: "This collage has expired"])
        }
        
        try await joinCollage(collageId: collage.id)
        
        return try await fetchCollage(collage: collage, user: user)
    }
    
    func fetchMemberships(userId: UUID) async throws -> [UUID] {
        // Check cache first
        if let cached = membershipCache[userId] {
            return cached
        }
        
        let memberships: [CollageMember] = try await supabase
            .from("collage_members")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        guard !memberships.isEmpty else {
            print("No memberships found for user: \(userId)")
            membershipCache[userId] = []
            return []
        }
        
        let collageIds = memberships.map { $0.collageId }
        print("Found \(collageIds.count) memberships")
        
        // Cache the result
        membershipCache[userId] = collageIds
        
        return collageIds
    }
    
    // OPTIMIZED: Fetch both active and expired in one call
    func fetchAllSessions(memberships: [UUID], user: CollageUser) async throws -> (active: [CollageSession], expired: [CollageSession]) {
        guard !memberships.isEmpty else {
            return ([], [])
        }
        
        // Fetch all collages in one call
        let collages: [Collage] = try await supabase
            .from("collages")
            .select()
            .in("id", values: memberships.map { $0.uuidString })
            .execute()
            .value
        
        
        let now = Date()
        var activeSessions: [CollageSession] = []
        var expiredSessions: [CollageSession] = []
        
        // Process all collages concurrently
        await withTaskGroup(of: (CollageSession?, Bool).self) { group in
            for collage in collages {
                group.addTask {
                    do {
                        let session = try await self.fetchCollage(collage: collage, user: user)
                        let isActive = collage.expiresAt > now
                        return (session, isActive)
                    } catch {
                        print("Error fetching collage \(collage.id): \(error)")
                        return (nil, false)
                    }
                }
            }
            
            for await (session, isActive) in group {
                if let session = session {
                    if isActive {
                        activeSessions.append(session)
                    } else {
                        expiredSessions.append(session)
                    }
                }
            }
        }
        
        
        return (activeSessions, expiredSessions)
    }
    
    func fetchActiveSessions(memberships: [UUID], user: CollageUser) async throws -> [CollageSession] {
        let now = ISO8601DateFormatter().string(from: Date())
        var collages: [Collage] = []
        
        do {
            collages = try await supabase
                .from("collages")
                .select()
                .in("id", values: memberships.map { $0.uuidString })
                .gt("expires_at", value: now)
                .execute()
                .value
        } catch {
            print("error fetching collages: \(error)")
        }
        
        var sessions: [CollageSession] = []
        for collage in collages {
            do {
                let session = try await fetchCollage(collage: collage, user: user)
                sessions.append(session)
            } catch {
                print("Error fetching collage \(collage.id): \(error)")
            }
        }
        
        return sessions
    }
    
    func fetchExpiredSession(memberships: [UUID], user: CollageUser) async throws -> [CollageSession] {
        let now = ISO8601DateFormatter().string(from: Date())
        let collages: [Collage] = try await supabase
            .from("collages")
            .select()
            .in("id", values: memberships.map { $0.uuidString })
            .lt("expires_at", value: now)
            .execute()
            .value
        
        var sessions: [CollageSession] = []
        for collage in collages {
            do {
                let session = try await fetchCollage(collage: collage, user: user)
                sessions.append(session)
            } catch {
                print("Error fetching collage \(collage.id): \(error)")
            }
        }
        
        return sessions
    }
    
    func fetchCollage(collage: Collage, user: CollageUser) async throws -> CollageSession {
        let collage: Collage = try await supabase
            .from("collages")
            .select()
            .eq("id", value: collage.id.uuidString)
            .single()
            .execute()
            .value
        
        let members = try await fetchCollageMembers(collageId: collage.id)
        let creator = members.filter { $0.id == collage.createdBy }.first ?? user
        
        // Only fetch photos for non-expired collages
        let photos: [CollagePhoto]
        let isExpired = collage.expiresAt < Date()
        
        if isExpired {
            // Auto-cleanup expired collage photos
            Task.detached(priority: .background) {
                try? await self.cleanupExpiredCollage(collageId: collage.id)
            }
            photos = []
        } else {
            photos = try await fetchPhotosForSession(sessionId: collage.id)
        }
        
        return CollageSession(
            id: collage.id,
            collage: collage,
            creator: creator,
            members: members,
            photos: photos
        )
    }
    
    //MARK: - User Functions
    
    func fetchUser(userId: UUID) async throws -> CollageUser {
        // Check cache first
        if let cachedUser = userCache[userId] {
            return cachedUser
        }
        
        let user: CollageUser = try await supabase
            .from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        // Cache the user
        userCache[userId] = user
        return user
    }
    
    func fetchCollageMembers(collageId: UUID) async throws -> [CollageUser] {
        let memberships: [CollageMember] = try await supabase
            .from("collage_members")
            .select()
            .eq("collage_id", value: collageId.uuidString)
            .execute()
            .value
        
        let userIds = memberships.map { $0.userId }
        
        guard !userIds.isEmpty else {
            return []
        }
        
        // Check which users are already cached
        let uncachedIds = userIds.filter { userCache[$0] == nil }
        
        // Fetch only uncached users
        if !uncachedIds.isEmpty {
            let users: [CollageUser] = try await supabase
                .from("users")
                .select()
                .in("id", values: uncachedIds.map { $0.uuidString })
                .execute()
                .value
            
            // Cache the newly fetched users
            users.forEach { userCache[$0.id] = $0 }
        }
        
        // Return all users from cache
        return userIds.compactMap { userCache[$0] }
    }
    
    func updateUsername(username: String) async throws {
        let user = try await getCurrentUser()
        
        struct UsernameUpdate: Encodable {
            let username: String
            let updated_at: String
        }
        
        let updateData = UsernameUpdate(
            username: username,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase
            .from("users")
            .update(updateData)
            .eq("id", value: user.id.uuidString)
            .execute()
        
        // Update cache
        if var cachedUser = userCache[user.id] {
            cachedUser.username = username
            userCache[user.id] = cachedUser
        }
    }
    
    //MARK: - Helper Functions
    
    private func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
    
    //MARK: - Storage Helper Functions

    func listFilesInFolder(bucket: String, folder: String) async throws -> [String] {
        let files = try await supabase.storage
            .from(bucket)
            .list(path: folder)
        
        return files.map { $0.name }
    }

    func getPublicURL(bucket: String, path: String) throws -> String {
        let publicURL = try supabase.storage
            .from(bucket)
            .getPublicURL(path: path)
        
        return publicURL.absoluteString
    }
}
