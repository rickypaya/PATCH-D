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
    
    // Predefined colors for collage thumbnails
    private let thumbnailColors: [Color] = [
        Color(hex: "94B8B9"), // Light blue-gray
        Color(hex: "E5BFAC"), // Light peach
        Color(hex: "EC955B"), // Orange
        Color(hex: "62B2A1"), // Teal
        Color(hex: "6A5858"), // Dark brown-gray
        Color(hex: "E5B154")  // Mustard yellow
    ]
    
    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            // Profile avatar background with specified color CA5230
            Circle()
                .fill(Color(hex: "CA5230"))
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
            // Hamburger menu button (left) - dropdown menu
            Menu {
                Button("Sign Out") {
                    Task {
                        try await appState.signOut()
                        dismiss()
                    }
                }
            } label: {
                Image("icon-hamburger")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
            }
            
            Spacer()
            
            // Center logo
            Image("Patch'd_logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 45)
            
            Spacer()
            
            // Back arrow button (right)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.5)) {
                    appState.navigateBack()
                }
            }, label: {
                Image(systemName: "arrow.left")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.black)
            })
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var userStatsSection: some View {
        
            // Statistics
            HStack(spacing: 20) {
    
                // Collages count
                VStack(spacing: 4) {
                    Text("\(userContributedCollages.count)")
                        .font(.custom("Sanchez-Regular", size: 20))
                        .foregroundColor(Color(hex: "000000"))
                    Text("Collages")
                        .font(.custom("Sanchez-Regular", size: 10))
                        .foregroundColor(Color(hex: "9F8860"))
                }
                
                
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
                           .font(.custom("Sanchez-Regular", size: 20))
                           .foregroundColor(Color(hex: "000000"))
                       Text("Friends")
                           .font(.custom("Sanchez-Regular", size: 10))
                           .foregroundColor(Color(hex: "9F8860"))
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
                           .font(.custom("Sanchez-Regular", size: 20))
                           .foregroundColor(Color(hex: "000000"))
                       Text("Invites")
                           .font(.custom("Sanchez-Regular", size: 10))
                           .foregroundColor(Color(hex: "9F8860"))
                   }
               }
        }
    }
    
    private var collageGridSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(0..<min(6, userContributedCollages.count), id: \.self) { index in
                let session = userContributedCollages[index]
                ProfileCollagePreviewCard(session: session, backgroundColor: thumbnailColors[index % thumbnailColors.count])
            }
        }
        .padding(.horizontal, 20)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with rounded top corners - beige top, cream bottom
                VStack(spacing: 0) {
                    // Beige section (EEDDC1) - fills top with rounded corners
                    Color(hex: "EEDDC1")
                        .frame(height: geometry.size.height * (150.0 / 744.0)) // Extended beige section
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 20,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 20
                            )
                        )
                    
                    // Cream section (FFFAF1) - fills remaining bottom space
                    Color(hex: "FFFAF1")
                        .frame(maxHeight: .infinity) // Fill remaining space
                }
                .offset(y: -7) // Move cream background up by 5px more (-2-5=-7)
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    topNavigationBar
                    
                    // Add more spacing to push content down to match UI
                    Spacer()
                        .frame(height: 20)
                    
                    ScrollView {
                        VStack(spacing: 30) {
                            // Avatar section - moved down to be nested within cream background
                            avatarView
                                .padding(.top, 40)
                            
                            VStack(spacing: 10){
                                Text(username.isEmpty ? "Jchung" : username)
                                    .font(.custom("Sanchez-Regular", size: 20))
                                    .foregroundColor(Color(hex: "000000"))
                                    

                                Text(userEmail)
                                    .font(.custom("Sanchez-Regular", size: 14))
                                    .foregroundColor(.black)
                                // Profile Name - Sanchez Regular 20, color 000000
                            }
                            
                            
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
        }
        .onAppear {
            username = appState.currentUser?.username ?? "Jchung"
            Task {
                await appState.loadPendingCollageInvites(forceRefresh: true)
            }
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
    let backgroundColor: Color
    
    // Computed property that reacts to session changes
    private var preview_url: String? {
        session.preview_url
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail image with real data
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
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
        .onTapGesture {
            appState.selectedSession = session
            appState.navigateTo(.fullscreen)
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
