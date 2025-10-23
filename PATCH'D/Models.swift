//
//  Models.swift
//  PATCH'D
//

import SwiftUI

// MARK: - Authentication Models

enum AuthError: Error, LocalizedError {
    case userAlreadyRegistered
    case invalidCredentials
    case userNotFound
    case networkError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .userAlreadyRegistered:
            return "This email is already registered"
        case .invalidCredentials:
            return "Invalid login credentials"
        case .userNotFound:
            return "User not found"
        case .networkError:
            return "Network error occurred"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

// MARK: - User Models

enum CurrState {
    case onboardingTitle
    case onboardingWelcome
    case onboardingSignUp
    case onboardingSignIn
    case registrationSuccess
    case onboarding1
    case onboarding2
    case onboarding3
    case onboarding4
    case homeScreen
    case homeCollageCarousel
    case createCollage
    case profile
    case dashboard
    case fullscreen
    case friendsList
    case collageInvites
    case final
}

struct CollageUser: Identifiable, Codable {
    var id: UUID
    var email: String
    var username: String
    var avatarUrl: String?
    var createdAt: Date
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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
    var backgroundUrl: String?
    var previewUrl: String?
    var isPartyMode: Bool
    
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
        case previewUrl = "preview_url"
        case isPartyMode = "is_party_mode"
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

struct CollagePhoto: Identifiable, Codable {
    var id: UUID
    var collage_id: UUID
    var user_id: UUID
    var image_url: String
    let position_x: Double
    let position_y: Double
    let rotation: Double
    let scale: Double
    let created_at: Date
    let updated_at: Date
    
    enum CodingKeys: String, CodingKey {
        case id, collage_id, user_id
        case position_x, position_y, rotation, scale
        case created_at, updated_at
        case image_url
    }

}

struct PhotoState {
    var offset: CGSize = .zero
    var rotation: Angle = .zero
    var scale: CGFloat = 1.0
    var lastOffset: CGSize = .zero
    var lastRotation: Angle = .zero
    var lastScale: CGFloat = 1.0
    var globalPosition: CGPoint = .zero
}

// MARK: - Composite Models (for UI convenience)

struct CollageSession: Identifiable {
    var id: UUID
    var collage: Collage
    var creator: CollageUser
    var members: [CollageUser]
    var photos: [CollagePhoto]
    
    //Collage Previews
    var preview_url: String? {
        collage.previewUrl ?? ""
    }
    var updated_at: Date?
    
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
        collage.backgroundUrl ?? ""
    }
    
    var isActive: Bool {
        let now = Date()
        return now >= startsAt && now <= expiresAt
    }
}


// MARK: - Friendship Models

struct Friendship: Codable {
    let id: UUID
    let userId: UUID
    let friendId: UUID
    let status: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case friendId = "friend_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Collage Invite Models

struct CollageInvite: Codable {
    let id: UUID
    let collageId: UUID
    let senderId: UUID
    let receiverId: UUID
    let status: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case collageId = "collage_id"
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
