//
//  Models.swift
//  PATCH'D
//

import SwiftUI

// MARK: - User Models

enum CurrState {
    case signUp
    case logIn
    case profile
//    case dashboard
//    case collage
}

struct CollageUser: Identifiable, Codable {
    var id: UUID
    var email: String
    var username: String
    var avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Theme Models

struct Theme: Identifiable, Codable {
    var id: UUID
    var text: String
    var category: String
    var isActive: Bool
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case category
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

// MARK: - Collage Models

struct Collage: Identifiable, Codable {
    var id: UUID
    var theme: String
    var createdBy: UUID
    var inviteCode: String
    var startsAt: Date
    var expiresAt: Date
    var createdAt: Date
    var updatedAt: Date
    var backgroundUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case theme
        case createdBy = "created_by"
        case inviteCode = "invite_code"
        case startsAt = "starts_at"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case backgroundUrl = "background_url"
    }
}

struct CollageMember: Identifiable, Codable {
    var id: UUID
    var collageId: UUID
    var userId: UUID
    var joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case collageId = "collage_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
    }
}

// MARK: - Photo Models

struct Photo: Identifiable, Codable {
    var id: UUID
    var collageId: UUID
    var userId: UUID
    var username: String
    var storageKey: String
    var imageUrl: String
    var positionX: CGFloat
    var positionY: CGFloat
    var width: CGFloat
    var height: CGFloat
    var rotation: CGFloat
    var aspectRatio: CGFloat
    var uploadedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case collageId = "collage_id"
        case userId = "user_id"
        case username
        case storageKey = "storage_key"
        case imageUrl = "image_url"
        case positionX = "position_x"
        case positionY = "position_y"
        case width
        case height
        case rotation
        case aspectRatio = "aspect_ratio"
        case uploadedAt = "uploaded_at"
    }
}

// MARK: - Invite Models

struct Invite: Identifiable, Codable {
    var id: UUID
    var code: String
    var collageId: UUID
    var createdBy: UUID
    var expiresAt: Date
    var maxUses: Int?
    var currentUses: Int
    var createdAt: Date
    var isActive: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case code
        case collageId = "collage_id"
        case createdBy = "created_by"
        case expiresAt = "expires_at"
        case maxUses = "max_uses"
        case currentUses = "current_uses"
        case createdAt = "created_at"
        case isActive = "is_active"
    }
}

// MARK: - Composite Models (for UI convenience)

struct CollageSession: Identifiable {
    var id: UUID
    var collage: Collage
    var creator: CollageUser
    var members: [CollageUser]
    var photos: [Photo]
    
    // Computed properties for convenience
    var theme: String {
        collage.theme
    }
    
    var inviteCode: String {
        collage.inviteCode
    }
    
    var startsAt: Date {
        collage.startsAt
    }
    
    var expiresAt: Date {
        collage.expiresAt
    }
    
    var backgroundUrl: String {
        collage.backgroundUrl
    }
    
    var isActive: Bool {
        let now = Date()
        return now >= startsAt && now <= expiresAt
    }
}
