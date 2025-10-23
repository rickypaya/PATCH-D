//
//  ProfileView.swift
//  PATCH'D
//
//  Created by Ricardo Payares on 10/15/25.
//

import SwiftUI

//MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var username: String = ""
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var selectedImage: UIImage?
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var confirmSignOut = false
    @Environment(\.dismiss) var dismiss
    // Real data for user's contributed collages (both created and joined)
    //corrected to archive data
    private var userContributedCollages: [CollageSession] {
//        appState.activeSessions.filter { session in
//            // Show collages where user is either the creator OR a member
//            session.creator.id == appState.currentUser?.id || 
//            session.members.contains { $0.id == appState.currentUser?.id }
//        }
        appState.archive
    }
    
    private var userEmail: String {
        guard let user = appState.currentUser else { return "Unknown User" }
        return user.email
    }
    
    // Total unique members across all user's contributed collages
    private var totalUniqueMembers: Int {
        let allMembers = userContributedCollages.flatMap { $0.members }
        let uniqueMemberIds = Set(allMembers.map { $0.id })
        return uniqueMemberIds.count
    }
    
    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            // Yellow circle background
            Circle()
                .fill(Color.yellow)
                .frame(width: 120, height: 120)
            
            // User's profile image inside
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else if let avatarUrl = appState.currentUser?.avatarUrl,
                      let url = URL(string: avatarUrl),
                      let user = appState.currentUser {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    case .failure(_), .empty:
                        defaultMemberAvatar(for: user)
                            .frame(width: 100, height: 100)
                    @unknown default:
                        defaultMemberAvatar(for: user)
                            .frame(width: 100, height: 100)
                    }
                }
            } else if let user = appState.currentUser {
                defaultMemberAvatar(for: user)
                    .frame(width: 100, height: 100)
            }
        }
        .onTapGesture {
            showImagePicker = true
        }
        .confirmationDialog("Sign Out?", isPresented: $confirmSignOut) {
            Button("Sign Out") { Task {
                try await appState.signOut()
                dismiss()
            } }
            Button("Cancel", role: .cancel) { confirmSignOut = false }
        }
    }
    
    private var topNavigationBar: some View {
        HStack {
            // Profile icon (left)
            Button(action:{
                confirmSignOut = true
            }, label: {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                    )
            })
            
            Spacer()
            
            // Center logo
            Image("Patch'd_logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 30)
            
            Spacer()
            
            // Back button -> Right
            Button(action: {
                appState.currentState = .dashboard
            }, label: {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "arrowshape.right.circle")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                    )
            })
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var userStatsSection: some View {
        VStack(spacing: 16) {
            // Username
            Text(username.isEmpty ? "Jericho" : username)
                .font(.custom("Sanchez", size: 24))
                .italic()
                .foregroundColor(.black)
            
            Text(userEmail)
                .font(.custom("Sanchez", size: 14))
                .foregroundColor(.black)
            
            // Statistics
            HStack(spacing: 40) {
                // Collages count
                VStack(spacing: 4) {
                    Text("\(userContributedCollages.count)")
                        .font(.custom("Sanchez", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text("Archived")
                        .font(.custom("Sanchez", size: 16))
                        .foregroundColor(.black.opacity(0.7))
                }
                
                // Divider
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                // Friends count (total unique members across all collages)
                //will change to some friends list implementation
                
                Button(action: {
                    Task {
                        appState.currentState = .friendsList
                    }
                }) {
                    VStack(spacing: 4) {
                        Text("\(appState.friends.count)")
                            .font(.custom("Sanchez", size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("Friends")
                            .font(.custom("Sanchez", size: 16))
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
                
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                
                Button(action: {
                    Task {
                        appState.currentState = .collageInvites
                    }
                }) {
                    VStack(spacing: 4) {
                        Text("\(appState.pendingCollageInvites.count)")
                            .font(.custom("Sanchez", size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("Invites")
                            .font(.custom("Sanchez", size: 16))
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
                
            }
            
            // Share Profile button
//            Button(action: {
//                // TODO: Implement share profile functionality
//            }) {
//                Text("Share Profile")
//                    .font(.custom("Sanchez", size: 18))
//                    .fontWeight(.bold)
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .frame(height: 50)
//                    .background(Color.black)
//                    .cornerRadius(12)
//            }
//            .padding(.horizontal, 40)
        }
    }
    
    private var collageGridSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(userContributedCollages.prefix(6), id: \.id) { session in
                ProfileCollagePreviewCard(session: session)
            }
        }
        .padding(.horizontal, 20)
    }
    
    var body: some View {
        ZStack {
            // Background with subtle gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white,
                    Color(red: 1.0, green: 0.98, blue: 0.9),
                    Color(red: 1.0, green: 0.95, blue: 0.85)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topNavigationBar
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Avatar section
                        avatarView
                            .padding(.top, 20)
                        
                        // User stats section
                        userStatsSection
                        
                        // Collage grid section
                        collageGridSection
                            .padding(.top, 20)
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            username = appState.currentUser?.username ?? "Jericho"
        }
        .confirmationDialog("Add Photo", isPresented: $showImagePicker) {
            Button("Take Photo") {
                showCamera = true
            }
            Button("Choose from Library") {
                showLibrary = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showLibrary) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            if let image = newValue {
                appState.updateUserAvatar(image)
                showCamera = false
                showLibrary = false
            }
        }
    }
}

// MARK: - Profile Collage Preview Card (Real Data)
struct ProfileCollagePreviewCard: View {
    @EnvironmentObject var appState: AppState
    let session: CollageSession
    @State var preview_url: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail image with real data
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 100) // Smaller height for Profile View
                
                if let previewUrl = preview_url, let url = URL(string: previewUrl) {
                    // Display preview image if available
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                                .cornerRadius(8)
                        case .failure(_), .empty:
                            emptyPreviewView
                        @unknown default:
                            emptyPreviewView
                        }
                    }
                    
                    // Photo count badge
                    if !session.photos.isEmpty {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("\(session.photos.count)")
                                    .font(.custom("Sanchez", size: 10))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(4)
                                    .padding(4)
                            }
                        }
                    }
                } else {
                    emptyPreviewView
                }
            }
            
            // Title below (smaller for Profile View)
            Text(session.theme)
                .font(.custom("Sanchez", size: 12))
                .fontWeight(.bold)
                .foregroundColor(.black)
                .lineLimit(1)
                .padding(.top, 4)
        }
        .onAppear {
            preview_url = session.preview_url ?? ""
        }
        .onTapGesture {
            appState.selectedSession = session
            appState.currentState = .final
        }
    }
    
    private var emptyPreviewView: some View {
        VStack(spacing: 4) {
            Image(systemName: "photo.stack")
                .font(.system(size: 20))
                .foregroundColor(.black.opacity(0.3))
            Text("No photos")
                .font(.custom("Sanchez", size: 10))
                .foregroundColor(.black.opacity(0.5))
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState.shared)
}
