//
//  DBManager.swift
//  PATCH'D
//
import SwiftUI
import Supabase

//MARK: - Collage DB Manager

class CollageDBManager {
    //Handles supabase db table management
    //Methods:
    //async getCurrentuser() -> Collage User
    //async SignUpWithEmail() -> AuthResponse
    //async SignIn() -> Session
    //async SignOut() -> None
    //async fetchRandomTheme() -> String
    //async createCollage(theme, duration) -> CollageSession
    //async updateCollageSessionPreview(sessionId, imageUrl) -> None
    //async fetchPhotosForSession(sessionId) -> [CollagePhoto]
    //async addPhotoToCollage(sessionId, imageURL, positionX, positionY) -> CollagePhoto
    //async updatePhotoTransform(photoId, positionX, positionY, rotation, scale) -> None
    //async uploadImage(image, bucket, folder, filename) -> String(filepath)
    //async uploadCollagePreview(sessionId, image) -> string (imageURL)
    //asubscribeToPhotoUpdates(sessionid, onchange) -> Task
    //async uploadUserAvatar(userId, image) -> String (filepath)
    //async joinCollage(collageId) -> None
    //async joinCollageByInviteCode(inviteCode) -> CollageSession
    //async fetchCollage(collageId) -> CollageSession
    //async fetchSessions() -> [CollageSession]
    //async fetchExpiredSession() -> [CollageSession]
    //async fetchUser(userId) -> CollageUser
    //async fetchCollageMembers(collageId) -> [CollageUsers]
    //async updateUserName(username) -> None
    //private generateInviteColde() -> String
    
    
    static let shared = CollageDBManager()
    //supabase manager - private to CollageDBManager class
    private let supabase: SupabaseClient
    
    private init() {
        supabase = SupabaseClient(
            //TODO: Hide Supabase Key with environment variables
            supabaseURL: URL(string: "https://bxrnvixgpktkuwqncafe.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4cm52aXhncGt0a3V3cW5jYWZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4ODU3NzEsImV4cCI6MjA3NTQ2MTc3MX0.hgluiRmwCUruyXvDrEwzDhtZ4zA2QdmClAt8GupIJgs"
        )
    }
    
    func getCurrentUser() async throws -> CollageUser {
        let session = try await supabase.auth.session
        let userId = session.user.id
        
        let response: CollageUser = try await supabase
            .from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
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
    }
    
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
    
    func createCollage(theme: String, duration: TimeInterval, isPartyMode: Bool) async throws -> CollageSession {
        // Get current user
        let user = try await getCurrentUser()
        
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
            let updated_at: String
            let background_url: String
            let isPartyMode: Bool
        }
        
        let collageData = CollageInsert(
            theme: theme,
            created_by: user.id.uuidString,
            invite_code: inviteCode,
            starts_at: ISO8601DateFormatter().string(from: now),
            expires_at: ISO8601DateFormatter().string(from: expiresAt),
            updated_at: ISO8601DateFormatter().string(from: now),
            background_url: "", // You may want to generate/select a background
            isPartyMode: isPartyMode
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
        
        let members = try await fetchCollageMembers(collageId: collage.id)
        
        // Return CollageSession
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
    
    func addPhotoToCollage(sessionId: UUID, imageURL: String, positionX: Double, positionY: Double ) async throws -> CollagePhoto {
        let user = try await getCurrentUser()
        
        struct collagePhotoInsert : Encodable {
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
        
        let response : CollagePhoto = try await supabase
            .from("photos")
            .insert(newPhoto)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func updatePhotoTransform (photoId: UUID, positionX: Double, positionY: Double, rotation: Double, scale: Double) async throws {
        try await supabase
            .from("photos")
            .update([
                "position_x": positionX,
                "position_y": positionY,
                "rotation": rotation,
                "scale": scale
            ])
            .eq("id", value: photoId)
            .execute()
    }
    
    func uploadImage(_ image: UIImage, bucket: String, folder: String, fileName: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "DBManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let filePath = "\(folder)/\(fileName)"
        
        try await supabase.storage
            .from(bucket)
            .upload(path: filePath, file: imageData, options: FileOptions(contentType: "image/png", upsert: true))
        
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
    func subscribeToPhotoUpdates(sessionId: UUID, onChange: @escaping ([CollagePhoto]) -> Void) -> Task <Void, Never> {
        
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
        // Compress image to JPEG data
        guard let imageData = image.pngData() else {
            throw NSError(domain: "DB", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        // Generate unique filename
        let filename = "\(userId.uuidString)_\(Date().timeIntervalSince1970).png"
        let filePath = "avatars/\(filename)"
        // Upload to Supabase storage
        try await supabase.storage
            .from("patchd-storage")
            .upload(path: filePath, file: imageData, options: FileOptions(contentType: "image/png"))
        // Get public URL
        let publicURL = try supabase.storage
            .from("patchd-storage")
            .getPublicURL(path: filePath)
        
        // Update user table with avatar URL
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
        
        return publicURL.absoluteString
    }
    
    
    
    func joinCollage(collageId: UUID) async throws {
        // Get current user
        let user = try await getCurrentUser()
        
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
        
        //TODO: Fetch Photos
        let photos = try await fetchPhotosForSession(sessionId: collageId)
        
        return CollageSession(
            id: collage.id,
            collage: collage,
            creator: creator,
            members: members,
            photos: photos
        )
    }
    
    func fetchSessions() async throws -> [CollageSession] {
        // Fetch collage IDs where user is a member
        let user = try await getCurrentUser()
        print("In fetch session for \(user.id)")
        
        let memberships: [CollageMember] = try await supabase
            .from("collage_members")
            .select()
            .eq("user_id", value: user.id)
            .execute()
            .value
        
        guard !memberships.isEmpty else {
            print ("No memberships found for user: \(user.id)")
            return []
        }
        
        let collageIds = memberships.map { $0.collageId }
        print("Found \(collageIds.count) memberships")
        
        guard !collageIds.isEmpty else {
            return []
        }
        
        // Fetch active collages
        let now = ISO8601DateFormatter().string(from: Date())
        var collages: [Collage] = []
        do {
            collages = try await supabase
                .from("collages")
                .select()
                .in("id", values: collageIds.map { $0.uuidString })
                .gt("expires_at", value: now)
                .execute()
                .value
            print(collages)
            
        }catch{
            print("error fetching collages: \(error)")
        }
        
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
    
    func fetchExpiredSession() async throws -> [CollageSession] {
        // Fetch collage IDs where user is a member
        let user = try await getCurrentUser()
        print("In fetch session for \(user.id)")
        
        let memberships: [CollageMember] = try await supabase
            .from("collage_members")
            .select()
            .eq("user_id", value: user.id)
            .execute()
            .value
        
        guard !memberships.isEmpty else {
            print ("No memberships found for user: \(user.id)")
            return []
        }
        
        let collageIds = memberships.map { $0.collageId }
        print("Found \(collageIds.count) memberships")
        
        guard !collageIds.isEmpty else {
            return []
        }
        
        // Fetch active collages
        let now = ISO8601DateFormatter().string(from: Date())
        let collages: [Collage] = try await supabase
            .from("collages")
            .select()
            .in("id", values: collageIds.map { $0.uuidString })
            .lt("expires_at", value: now)
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
        }
    
    //MARK: - Helper Functions
    
    private func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Excluding similar looking characters
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
