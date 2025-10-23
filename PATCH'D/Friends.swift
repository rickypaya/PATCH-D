//
//  FriendsListView.swift
//  PATCH'D
//
//  Friends list with tab-based navigation between Friends, Pending, and Sent requests
//

import SwiftUI

// MARK: - Friends List View
struct FriendsListView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: FriendTab = .friends
    @State private var showAddFriend = false
    @State private var searchText = ""
    
    enum FriendTab: String, CaseIterable {
        case friends = "Friends"
        case pending = "Pending"
        case sent = "Sent"
    }
    
    private var topNavigationBar: some View {
        HStack {
            // Back button (left)
            Button(action: {
                appState.currentState = .profile
            }) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                    )
            }
            
            Spacer()
            
            // Center title
            Text("Friends")
                .font(.custom("Sanchez", size: 24))
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Spacer()
            
            // Add friend button (right)
            Button(action: {
                showAddFriend = true
            }) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.badge.plus.fill")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(FriendTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.custom("Sanchez", size: 16))
                            .fontWeight(selectedTab == tab ? .bold : .regular)
                            .foregroundColor(selectedTab == tab ? .black : .black.opacity(0.5))
                        
                        // Badge for counts
                        if tab == .pending && appState.pendingFriendRequestCount > 0 {
                            Text("\(appState.pendingFriendRequestCount)")
                                .font(.custom("Sanchez", size: 12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                        } else if tab == .sent && !appState.sentFriendRequests.isEmpty {
                            Text("\(appState.sentFriendRequests.count)")
                                .font(.custom("Sanchez", size: 12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.gray)
                                .clipShape(Capsule())
                        }
                        
                        // Active indicator
                        Rectangle()
                            .fill(selectedTab == tab ? Color.yellow : Color.clear)
                            .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    var body: some View {
        ZStack {
            // Background gradient
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
                tabSelector
                
                // Search bar (only for friends tab)
                if selectedTab == .friends && !appState.friends.isEmpty {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.black.opacity(0.5))
                        TextField("Search friends...", text: $searchText)
                            .font(.custom("Sanchez", size: 16))
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 15)
                }
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    FriendsTabContent(searchText: searchText)
                        .tag(FriendTab.friends)
                    
                    PendingRequestsTabContent()
                        .tag(FriendTab.pending)
                    
                    SentRequestsTabContent()
                        .tag(FriendTab.sent)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            
            // Loading overlay
            if appState.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.yellow)
            }
        }
        .sheet(isPresented: $showAddFriend) {
            AddFriendSheet()
                .environmentObject(appState)
        }
        .onAppear {
            Task {
                await appState.loadFriends()
                await appState.loadPendingFriendRequests()
                await appState.loadSentFriendRequests()
            }
        }
    }
}

// MARK: - Friends Tab Content
struct FriendsTabContent: View {
    @EnvironmentObject var appState: AppState
    let searchText: String
    
    private var filteredFriends: [CollageUser] {
        if searchText.isEmpty {
            return appState.friends
        }
        return appState.searchFriends(query: searchText)
    }
    
    var body: some View {
        ScrollView {
            if filteredFriends.isEmpty {
                EmptyStateView(
                    icon: "person.2.slash",
                    title: searchText.isEmpty ? "No Friends Yet" : "No Results",
                    message: searchText.isEmpty ? "Add friends to start creating collages together!" : "No friends found matching '\(searchText)'"
                )
                .padding(.top, 100)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredFriends, id: \.id) { friend in
                        FriendCard(user: friend)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Pending Requests Tab Content
struct PendingRequestsTabContent: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            if appState.pendingFriendRequests.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "No Pending Requests",
                    message: "You're all caught up!"
                )
                .padding(.top, 100)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(appState.pendingFriendRequests, id: \.friendship.id) { request in
                        PendingRequestCard(
                            friendship: request.friendship,
                            user: request.user
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Sent Requests Tab Content
struct SentRequestsTabContent: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            if appState.sentFriendRequests.isEmpty {
                EmptyStateView(
                    icon: "paperplane",
                    title: "No Sent Requests",
                    message: "Friend requests you send will appear here"
                )
                .padding(.top, 100)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(appState.sentFriendRequests, id: \.id) { friendship in
                        SentRequestCard(friendship: friendship)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Friend Card
struct FriendCard: View {
    @EnvironmentObject var appState: AppState
    let user: CollageUser
    @State private var showRemoveConfirmation = false
    @State private var friendshipId: UUID?
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            UserAvatarView(user: user, size: 50)
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.custom("Sanchez", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text(user.email)
                    .font(.custom("Sanchez", size: 14))
                    .foregroundColor(.black.opacity(0.6))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Remove button
            Button(action: {
                showRemoveConfirmation = true
            }) {
                Image(systemName: "person.fill.xmark")
                    .font(.system(size: 18))
                    .foregroundColor(.red)
                    .padding(10)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(15)
        .background(Color.white.opacity(0.9))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .confirmationDialog("Remove Friend?", isPresented: $showRemoveConfirmation) {
            Button("Remove \(user.username)", role: .destructive) {
                Task {
                    if let id = await appState.getFriendshipId(for: user.id) {
                        await appState.removeFriend(id, userId: user.id)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove \(user.username) from your friends?")
        }
    }
}

// MARK: - Pending Request Card
struct PendingRequestCard: View {
    @EnvironmentObject var appState: AppState
    let friendship: Friendship
    let user: CollageUser
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            UserAvatarView(user: user, size: 50)
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.custom("Sanchez", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text("wants to be friends")
                    .font(.custom("Sanchez", size: 14))
                    .foregroundColor(.black.opacity(0.6))
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 10) {
                // Accept button
                Button(action: {
                    Task {
                        await appState.acceptFriendRequest(friendship.id)
                    }
                }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.green)
                        .clipShape(Circle())
                }
                
                // Reject button
                Button(action: {
                    Task {
                        await appState.rejectFriendRequest(friendship.id)
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
        }
        .padding(15)
        .background(Color.white.opacity(0.9))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Sent Request Card
struct SentRequestCard: View {
    @EnvironmentObject var appState: AppState
    let friendship: Friendship
    @State private var friendUser: CollageUser?
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            if let user = friendUser {
                UserAvatarView(user: user, size: 50)
                
                // User info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.username)
                        .font(.custom("Sanchez", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("Request pending")
                        .font(.custom("Sanchez", size: 14))
                        .foregroundColor(.black.opacity(0.6))
                }
            } else {
                // Loading state
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Loading...")
                        .font(.custom("Sanchez", size: 18))
                        .foregroundColor(.black.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Pending indicator
            Text("PENDING")
                .font(.custom("Sanchez", size: 12))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray)
                .cornerRadius(8)
        }
        .padding(15)
        .background(Color.white.opacity(0.9))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .task {
            do {
                friendUser = try await CollageDBManager.shared.fetchUser(userId: friendship.friendId)
            } catch {
                print("Failed to load user: \(error)")
            }
        }
    }
}

// MARK: - Add Friend Sheet
struct AddFriendSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var searchQuery = ""
    @State private var searchResults: [CollageUser] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 1.0, green: 0.98, blue: 0.9)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.black.opacity(0.5))
                        TextField("Username or email", text: $searchQuery)
                            .font(.custom("Sanchez", size: 16))
                            .autocapitalization(.none)
                            .textContentType(.username)
                        
                        if !searchQuery.isEmpty {
                            Button(action: {
                                searchQuery = ""
                                searchResults = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.black.opacity(0.5))
                            }
                        }
                    }
                    .padding(15)
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    // Search button
                    Button(action: searchUsers) {
                        Text("Search")
                            .font(.custom("Sanchez", size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(searchQuery.isEmpty ? Color.gray : Color.black)
                            .cornerRadius(12)
                    }
                    .disabled(searchQuery.isEmpty || isSearching)
                    .padding(.horizontal, 20)
                    
                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.custom("Sanchez", size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
                    
                    // Results
                    if isSearching {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.yellow)
                            .padding(.top, 50)
                    } else if !searchResults.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(searchResults, id: \.id) { user in
                                    SearchResultCard(user: user) {
                                        dismiss()
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    } else if searchQuery.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.black.opacity(0.3))
                            Text("Search for friends")
                                .font(.custom("Sanchez", size: 18))
                                .foregroundColor(.black.opacity(0.5))
                        }
                        .padding(.top, 100)
                    }
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchUsers() {
            isSearching = true
            errorMessage = nil
            
            Task {
                do {
                    searchResults = try await appState.searchUsers(query: searchQuery)
                    
                    if searchResults.isEmpty {
                        errorMessage = "No users found"
                    }
                    
                    isSearching = false
                } catch {
                    errorMessage = "Search failed: \(error.localizedDescription)"
                    isSearching = false
                }
            }
        }
}

// MARK: - Search Result Card
struct SearchResultCard: View {
    @EnvironmentObject var appState: AppState
    let user: CollageUser
    let onRequestSent: () -> Void
    @State private var friendshipStatus: String?
    @State private var isLoading = false
    
    var body: some View {
        HStack(spacing: 15) {
            UserAvatarView(user: user, size: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.custom("Sanchez", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text(user.email)
                    .font(.custom("Sanchez", size: 14))
                    .foregroundColor(.black.opacity(0.6))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Action button based on status
            actionButton
        }
        .padding(15)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .task {
            friendshipStatus = await appState.checkFriendshipStatus(with: user.id)
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        if isLoading {
            ProgressView()
                .scaleEffect(0.8)
        } else if let status = friendshipStatus {
            switch status {
            case "accepted":
                Text("FRIENDS")
                    .font(.custom("Sanchez", size: 12))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(8)
            case "pending":
                Text("PENDING")
                    .font(.custom("Sanchez", size: 12))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray)
                    .cornerRadius(8)
            default:
                addButton
            }
        } else {
            addButton
        }
    }
    
    private var addButton: some View {
        Button(action: {
            isLoading = true
            Task {
                await appState.sendFriendRequest(to: user.id)
                friendshipStatus = "pending"
                isLoading = false
                onRequestSent()
            }
        }) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.yellow)
                .clipShape(Circle())
        }
    }
}

// MARK: - User Avatar View
struct UserAvatarView: View {
    let user: CollageUser
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.yellow)
                .frame(width: size, height: size)
            
            if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size - 4, height: size - 4)
                            .clipShape(Circle())
                    case .failure(_), .empty:
                        defaultAvatar
                    @unknown default:
                        defaultAvatar
                    }
                }
            } else {
                defaultAvatar
            }
        }
    }
    
    private var defaultAvatar: some View {
        Text(String(user.username.prefix(1)).uppercased())
            .font(.custom("Sanchez", size: size * 0.4))
            .fontWeight(.bold)
            .foregroundColor(.black)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.black.opacity(0.3))
            
            Text(title)
                .font(.custom("Sanchez", size: 22))
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text(message)
                .font(.custom("Sanchez", size: 16))
                .foregroundColor(.black.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    FriendsListView()
        .environmentObject(AppState.preview())
}
