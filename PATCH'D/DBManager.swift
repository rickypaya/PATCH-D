//
//  DBManager.swift
//  PATCH'D
//
import SwiftUI
import Supabase

//MARK: - Supabase Manager

class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            //TODO: Hide Supabase Key with environment variables
            supabaseURL: URL(string: "https://bxrnvixgpktkuwqncafe.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4cm52aXhncGt0a3V3cW5jYWZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4ODU3NzEsImV4cCI6MjA3NTQ2MTc3MX0.hgluiRmwCUruyXvDrEwzDhtZ4zA2QdmClAt8GupIJgs"
        )
    }
    
    func signUpWithEmail(email: String, password: String) async throws -> AuthResponse {
        let authResp = try await client.auth.signUp(email: email, password: password)
        return authResp
    }
    
    func signIn(email: String, password: String) async throws -> Session {
        let authResp = try await client.auth.signIn(email: email, password: password)
        return authResp
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func getCurrentUser() async throws -> User {
        let session = try await client.auth.session
        return session.user
    }
}

//MARK: - Collage DB Manager

class CollageDBManager {
    static let shared = CollageDBManager()
    private let supabase = SupabaseManager.shared.client
    
    private init() {}
    
    //MARK: - Theme Functions
    
    func fetchRandomTheme() async throws -> String {
        // Fetch active themes and select one randomly
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
    
    func createCollage(theme: String, duration: TimeInterval) async throws -> CollageSession {
        // Get current user
        let user = try await SupabaseManager.shared.getCurrentUser()
        
        // Generate unique 8-character invite code
        let inviteCode = generateInviteCode()
        
        // Calculate timestamps
        let now = Date()
        let expiresAt = now.addingTimeInterval(duration)
        
        // Create collage record
        struct CollageInsert: Encodable {
            let theme: String
            let created_by: String
            let invite_code: String
            let starts_at: String
            let expires_at: String
            let background_url: String
        }
        
        let collageData = CollageInsert(
            theme: theme,
            created_by: user.id.uuidString,
            invite_code: inviteCode,
            starts_at: ISO8601DateFormatter().string(from: now),
            expires_at: ISO8601DateFormatter().string(from: expiresAt),
            background_url: "" // You may want to generate/select a background
        )
        
        let collage: Collage = try await supabase
            .from("collages")
            .insert(collageData)
            .select()
            .single()
            .execute()
            .value
        
        // Automatically add creator as a member
        try await joinCollage(collageId: collage.id)
        
        // Fetch the user profile
        let creator = try await fetchUser(userId: user.id)
        
        // Return CollageSession
        return CollageSession(
            id: collage.id,
            collage: collage,
            creator: creator,
            members: [creator],
            photos: []
        )
    }
    
    func joinCollage(collageId: UUID) async throws {
        // Get current user
        let user = try await SupabaseManager.shared.getCurrentUser()
        
        // Check if already a member
        let existingMembers: [CollageMember] = try await supabase
            .from("collage_members")
            .select()
            .eq("collage_id", value: collageId.uuidString)
            .eq("user_id", value: user.id.uuidString)
            .execute()
            .value
        
        guard existingMembers.isEmpty else {
            return // Already a member
        }
        
        // Insert new member
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
    }
    
    func joinCollageByInviteCode(inviteCode: String) async throws -> CollageSession {
        // Find collage by invite code
        let collages: [Collage] = try await supabase
            .from("collages")
            .select()
            .eq("invite_code", value: inviteCode)
            .execute()
            .value
        
        guard let collage = collages.first else {
            throw NSError(domain: "DB", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invalid invite code"])
        }
        
        // Check if collage is still active
        guard collage.expiresAt > Date() else {
            throw NSError(domain: "DB", code: 410, userInfo: [NSLocalizedDescriptionKey: "This collage has expired"])
        }
        
        // Join the collage
        try await joinCollage(collageId: collage.id)
        
        // Return the full collage session
        return try await fetchCollage(collageId: collage.id)
    }
    
    func fetchCollage(collageId: UUID) async throws -> CollageSession {
        // Fetch collage
        let collage: Collage = try await supabase
            .from("collages")
            .select()
            .eq("id", value: collageId.uuidString)
            .single()
            .execute()
            .value
        
        // Fetch creator
        let creator = try await fetchUser(userId: collage.createdBy)
        
        // Fetch members
        let members = try await fetchCollageMembers(collageId: collageId)
        
        // Fetch photos
        let photos = try await fetchCollagePhotos(collageId: collageId)
        
        return CollageSession(
            id: collage.id,
            collage: collage,
            creator: creator,
            members: members,
            photos: photos
        )
    }
    
    func fetchActiveSessions(for userId: UUID) async throws -> [CollageSession] {
        // Fetch collage IDs where user is a member
        let memberships: [CollageMember] = try await supabase
            .from("collage_members")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        let collageIds = memberships.map { $0.collageId }
        
        guard !collageIds.isEmpty else {
            return []
        }
        
        // Fetch active collages
        let now = ISO8601DateFormatter().string(from: Date())
        let collages: [Collage] = try await supabase
            .from("collages")
            .select()
            .in("id", values: collageIds.map { $0.uuidString })
            .gt("expires_at", value: now)
            .execute()
            .value
        
        // Build CollageSession objects
        var sessions: [CollageSession] = []
        for collage in collages {
            do {
                let session = try await fetchCollage(collageId: collage.id)
                sessions.append(session)
            } catch {
                print("Error fetching collage \(collage.id): \(error)")
            }
        }
        
        return sessions
    }
    
    //MARK: - Photo Functions
    
    func uploadPhoto(collageId: UUID, image: UIImage, position: CGPoint, size: CGSize, rotation: CGFloat) async throws -> Photo {
        // Get current user
        let user = try await SupabaseManager.shared.getCurrentUser()
        let userProfile = try await fetchUser(userId: user.id)
        
        // Compress image to JPEG
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "Image", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        // Generate unique filename
        let filename = "\(collageId.uuidString)/\(UUID().uuidString).jpg"
        let storageKey = filename
        
        // Upload to Supabase Storage
        let uploadResponse = try await supabase.storage
            .from("collage-photos")
            .upload(storageKey, data: imageData, options: FileOptions(contentType: "image/jpeg"))
        
        // Get public URL
        let publicURL = try supabase.storage
            .from("collage-photos")
            .getPublicURL(path: storageKey)
        
        // Calculate aspect ratio
        let aspectRatio = image.size.width / image.size.height
        
        // Insert photo record
        struct PhotoInsert: Encodable {
            let collage_id: String
            let user_id: String
            let username: String
            let storage_key: String
            let image_url: String
            let position_x: Double
            let position_y: Double
            let width: Double
            let height: Double
            let rotation: Double
            let aspect_ratio: Double
        }
        
        let photoData = PhotoInsert(
            collage_id: collageId.uuidString,
            user_id: user.id.uuidString,
            username: userProfile.username,
            storage_key: storageKey,
            image_url: publicURL.absoluteString,
            position_x: Double(position.x),
            position_y: Double(position.y),
            width: Double(size.width),
            height: Double(size.height),
            rotation: Double(rotation),
            aspect_ratio: Double(aspectRatio)
        )
        
        let photo: Photo = try await supabase
            .from("photos")
            .insert(photoData)
            .select()
            .single()
            .execute()
            .value
        
        return photo
    }
    
    func fetchCollagePhotos(collageId: UUID) async throws -> [Photo] {
        let photos: [Photo] = try await supabase
            .from("photos")
            .select()
            .eq("collage_id", value: collageId.uuidString)
            .order("uploaded_at", ascending: true)
            .execute()
            .value
        
        return photos
    }
    
    func deletePhoto(photoId: UUID) async throws {
        // Fetch photo to get storage key
        let photo: Photo = try await supabase
            .from("photos")
            .select()
            .eq("id", value: photoId.uuidString)
            .single()
            .execute()
            .value
        
        // Delete from storage
        try await supabase.storage
            .from("collage-photos")
            .remove(paths: [photo.storageKey])
        
        // Delete record from database
        try await supabase
            .from("photos")
            .delete()
            .eq("id", value: photoId.uuidString)
            .execute()
    }
    
    func updatePhotoPosition(photoId: UUID, position: CGPoint, size: CGSize, rotation: CGFloat) async throws {
        struct PhotoUpdate: Encodable {
            let position_x: Double
            let position_y: Double
            let width: Double
            let height: Double
            let rotation: Double
        }
        
        let updateData = PhotoUpdate(
            position_x: Double(position.x),
            position_y: Double(position.y),
            width: Double(size.width),
            height: Double(size.height),
            rotation: Double(rotation)
        )
        
        try await supabase
            .from("photos")
            .update(updateData)
            .eq("id", value: photoId.uuidString)
            .execute()
    }
    
    //MARK: - User Functions
    
    func fetchUser(userId: UUID) async throws -> CollageUser {
        let user: CollageUser = try await supabase
            .from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        return user
    }
    
    func fetchCollageMembers(collageId: UUID) async throws -> [CollageUser] {
        // Fetch member IDs
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
        
        // Fetch user profiles
        let users: [CollageUser] = try await supabase
            .from("users")
            .select()
            .in("id", values: userIds.map { $0.uuidString })
            .execute()
            .value
        
        return users
    }
    
    func updateUsername(username: String) async throws {
            // Get current user
            let user = try await SupabaseManager.shared.getCurrentUser()
            
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
        }
    
    //MARK: - Helper Functions
    
    private func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Excluding similar looking characters
        return String((0..<8).map { _ in characters.randomElement()! })
    }
}
