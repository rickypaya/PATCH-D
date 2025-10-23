//
//  HomeScreen.swift
//  PATCH'D
//
//  Created by merging DashboardView and HomeScreenView
//

import SwiftUI

// MARK: - Home Screen (Merged Dashboard + Home Screen)
struct HomeScreenView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCreateCollageSheet = false
    @State private var showInviteCodeSheet = false
    @State private var showArchiveSheet = false
    
    var body: some View {
        ZStack {
            // Background color EEDDC1 (Home Screen styling)
            Color(red: 0.933, green: 0.867, blue: 0.757).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top navigation bar (Home Screen styling)
                topNavigationBar
                
                // Main content area
                if appState.isLoading {
                    loadingView
                } else if appState.activeSessions.isEmpty {
                    emptyStateView
                } else {
                    collageGridView
                }
                
                Spacer()
                
                // Bottom Create button (Home Screen styling)
                createButton
            }
        }
        .sheet(isPresented: $showCreateCollageSheet) {
            CreateCollageSheet()
        }
        .sheet(isPresented: $showInviteCodeSheet) {
            InviteCodeSheet()
        }
        .sheet(isPresented: $showArchiveSheet) {
            ArchiveSheet()
        }
        .onAppear {
            print("DEBUG: HomeScreenView appeared")
            print("DEBUG: Current user: \(appState.currentUser?.email ?? "nil")")
            print("DEBUG: Is authenticated: \(appState.isAuthenticated)")
            if appState.currentUser == nil {
                print("DEBUG: No current user, redirecting to onboardingWelcome")
                appState.currentState = .onboardingWelcome
            } else {
                print("DEBUG: User authenticated, staying on home screen")
            }
        }
    }
    
    // MARK: - Top Navigation Bar
    private var topNavigationBar: some View {
        HStack {
            // Profile icon
            Button(action: {
                withAnimation(.easeInOut(duration: 0.5)) {
                    appState.currentState = .profile
                }
            }) {
                Circle()
                    .fill(Color(red: 0.792, green: 0.322, blue: 0.188)) // CA5230
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white) // FFFFFF
                            .font(.system(size: 20))
                    )
            }
            
            Spacer()
            
            // Center logo
            Image("Patch'd_logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 30)
            
            Spacer()
            
            Button(action: {
                showInviteCodeSheet.toggle()
            }, label: {
                Circle()
                    .fill(Color(red: 0.792, green: 0.322, blue: 0.188)) // CA5230
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "link.badge.plus" )
                            .foregroundColor(.white) // FFFFFF
                            .font(.system(size: 20))
                    )
            })
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .zIndex(10)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .black))
            Spacer()
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.black.opacity(0.3))
            
            Text("No Active Collages")
                .font(.custom("Sanchez", size: 24))
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text("Create a collage or join with an invite code")
                .font(.custom("Sanchez", size: 16))
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Collage Grid View (Real Data)
    private var collageGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(appState.activeSessions) { session in
                    RealCollagePreviewCard(session: session)
                        .onTapGesture {
                            Task {
                                await appState.selectCollageSession(session)
                                try? await Task.sleep(nanoseconds: 200_000_000)
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Create Button
    private var createButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                appState.currentState = .createCollage
            }
        }) {
            Text("Create")
                .font(.custom("Sanchez", size: 18))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(red: 0.220, green: 0.376, blue: 0.243)) // 38603E
                .cornerRadius(12)
                .overlay(
                    // Dotted patched border - 2px inside
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            Color(red: 0.067, green: 0.224, blue: 0.090), // 113917
                            style: StrokeStyle(lineWidth: 2, dash: [4, 4])
                        )
                        .padding(2)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 50)
    }
}

// MARK: - Real Collage Preview Card (From Dashboard)
struct RealCollagePreviewCard: View {
    let session: CollageSession
    @State var preview_url: String?
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Collage Preview Image
            previewImageView
            
            VStack(alignment: .leading, spacing: 8) {
                // Theme
                Text(session.theme)
                    .font(.custom("Sanchez", size: 16))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .lineLimit(1)
//                
//                // Time Remaining
//                Text(timeRemainingText)
//                    .font(.custom("Sanchez", size: 12))
//                    .foregroundColor(.black.opacity(0.7))
                
                TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
                    
                    var timerDownStyle : SystemFormatStyle.Timer {
                        .timer(countingUpIn: Date()..<session.expiresAt)
                    }
                    
                    Text(session.expiresAt, format: timerDownStyle)
                        .font(.custom("Sanchez", size: 12))
                        .foregroundColor(.black.opacity(0.7))
                        .onAppear {
                            if context.date >= session.expiresAt {
                                //Call alert for expired collage
                                //show notification on collage in dashboad?
                            }
                        }
                }
                
                // Photo count badge
                if !session.photos.isEmpty {
                    
                    HStack {
                        // Members Count
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .foregroundColor(.black.opacity(0.7))
                            Text("\(session.members.count)")
                                .font(.custom("Sanchez", size: 14))
                                .foregroundColor(.black.opacity(0.7))
                            
                            Spacer()
                            
                            Text("\(session.photos.count) photo\(session.photos.count == 1 ? "" : "s")")
                                .font(.custom("Sanchez", size: 12))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(6)
                                .padding(6)
                        }
                        
                    }
                }
            }
            .padding(4)
            .background(Color.white.opacity(0.6))
            .shadow(color: Color.gray.opacity(0.5), radius: 4, x: 0, y: -2)
            
        }
        .background(Color.white.opacity(0.8))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            preview_url = session.preview_url ?? ""
        }
        
        
        
    }

    
    private var previewImageView: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(12)
            
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
                            .cornerRadius(12)
                    case .failure(_), .empty:
                        emptyPreviewView
                    @unknown default:
                        emptyPreviewView
                    }
                }
            } else {
                emptyPreviewView
            }
        }
    }
    
    private var emptyPreviewView: some View {
        VStack(spacing: 8) {
            // Use different colors for each collage frame
            let colors: [Color] = [
                Color(red: 0.863, green: 0.675, blue: 0.675), // DCACAC
                Color(red: 0.416, green: 0.345, blue: 0.345), // 6A5858
                Color(red: 0.580, green: 0.722, blue: 0.725), // 94B8B9
                Color(red: 0.898, green: 0.749, blue: 0.675)  // E5BFAC
            ]
            
            let colorIndex = (session.id.hashValue % 4 + 4) % 4
            let selectedColor = colors[colorIndex]
            
            Rectangle()
                .fill(selectedColor)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(12)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.7))
                        Text("No photos yet")
                            .font(.custom("Sanchez", size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                )
        }
    }
    
    private var timeRemainingText: String {
        let remaining = session.expiresAt.timeIntervalSinceNow
        if remaining <= 0 {
            return "Expired"
        }
        
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(minutes)m left"
        }
    }
}

// MARK: - Invite Code Sheet
struct InviteCodeSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var inviteCode = ""
    @State private var isJoining = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Join a Collage")
                    .font(.title.bold())
                
                Text("Enter the 8-character invite code")
                    .font(.body)
                    .foregroundColor(.gray)
                
                TextField("Invite Code", text: $inviteCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(.horizontal)
                    .onChange(of: inviteCode) {
                        inviteCode = inviteCode.uppercased()
                    }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Button(action: joinCollage) {
                    if isJoining {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Join Collage")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(inviteCode.count == 8 ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(inviteCode.count != 8 || isJoining)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func joinCollage() {
        errorMessage = nil
        isJoining = true
        
        Task {
            do {
                _ = try await CollageDBManager.shared.joinCollageByInviteCode(inviteCode: inviteCode, user: appState.currentUser!)
                await appState.loadCollageSessions()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isJoining = false
        }
    }
}

#Preview("Home Screen") {
    HomeScreenView()
        .environmentObject(AppState.shared)
}

// MARK: - Preview Wrapper for Navigation Demo
struct HomeScreenToCreateCollagePreview: View {
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        ZStack {
            switch appState.currentState {
            case .homeScreen:
                HomeScreenView()
            case .createCollage:
                CreateCollageView()
            default:
                HomeScreenView()
            }
        }
        .onAppear {
            // Start with home screen
            appState.currentState = .homeScreen
        }
    }
}

#Preview("Home Screen → Create Collage Navigation") {
    HomeScreenToCreateCollagePreview()
        .environmentObject(AppState.shared)
}
