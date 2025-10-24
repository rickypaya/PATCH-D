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
    @State private var showInviteCodeSheet = false
    
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
        .sheet(isPresented: $showInviteCodeSheet) {
            InviteCodeSheet()
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
                    appState.navigateToProfile()
                }
            }) {
                Image("icon-profile")
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
            
            Button(action: {
                showInviteCodeSheet.toggle()
            }, label: {
                Image("icon-join")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
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
                ForEach(Array(appState.activeSessions.enumerated()), id: \.element.id) { index, session in
                    RealCollagePreviewCard(session: session, backgroundColor: thumbnailColors[index % thumbnailColors.count], photoCount: appState.collagePhotos.count)
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
    
    // Predefined colors for collage thumbnails in specified order
    private let thumbnailColors: [Color] = [
        Color(hex: "DCACAC") as Color, // Light pink
        Color(hex: "6A5858") as Color, // Dark brown-gray
        Color(hex: "94B8B9") as Color, // Light blue-gray
        Color(hex: "E5BFAC") as Color  // Light peach
    ]
    
    // MARK: - Create Button
    private var createButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                appState.navigateTo(.createCollage)
            }
        }) {
            ZStack {
                // Background image
                Image("blockbutton-blank-green")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .clipped()
                
                // Text overlay
                Text("Create")
                    .font(.custom("Sanchez", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .offset(y: -5) // Move text up by 5px total
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 50)
    }
}

// MARK: - Real Collage Preview Card (From Dashboard)
struct RealCollagePreviewCard: View {
    @EnvironmentObject var appState: AppState
    let session: CollageSession
    let backgroundColor: Color
    let photoCount: Int
    @State var preview_url: String?
    @State private var showExpirationAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top colored rectangle (collage preview)
            previewImageView
            
            // Bottom text section
            VStack(alignment: .leading, spacing: 4) {
                // Collage name
                Text(session.theme)
                    .font(.custom("Sanchez", size: 16))
                    .fontWeight(.regular)
                    .foregroundColor(Color(hex: "000000"))
                    .lineLimit(1)
                
                // Time remaining
                Text(timeRemainingText)
                    .font(.custom("Sanchez", size: 12))
                    .fontWeight(.regular)
                    .foregroundColor(Color(hex: "595245"))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(hex: "FDFBF5"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            preview_url = session.preview_url ?? ""
        }
        .alert("Collage Expired", isPresented: $showExpirationAlert) {
            Button("View Final Collage", role: .none) {
                appState.selectedSession = session
                appState.currentState = .final
            }
            Button("Dismiss", role: .cancel) {
                // Move to archive
                Task {
                    await appState.refreshActiveSessions()
                }
            }
        } message: {
            Text("Your collage '\(session.theme)' has expired. View the final collage or dismiss to move it to archive.")
        }
    }

    
    private var previewImageView: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
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
        .cornerRadius(12)
    }
    
    private var emptyPreviewView: some View {
        // Use different colors for each collage frame matching the UI design
        let colors: [Color] = [
            Color(hex: "DCACAC"), // Top left - Light pink/beige
            Color(hex: "6A5858"), // Top right - Dark brown/grey
            Color(hex: "94B8B9"), // Next row left - Light blue/teal
            Color(hex: "E5BFAC")  // Next row right - Light peach/orange
        ]
        
        let colorIndex = (session.id.hashValue % 4 + 4) % 4
        let selectedColor = colors[colorIndex]
        
        return Rectangle()
            .fill(selectedColor)
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(12)
    }
    
    private var timeRemainingText: String {
        let remaining = session.expiresAt.timeIntervalSinceNow
        if remaining <= 0 {
            return "Expired"
        }
        let days = Int(remaining) / 86400
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m left"
        } else if hours > 0 {
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

    // Colors matching the design requirements
    private var backgroundColor: Color { Color(hex: "F2E2C8") }
    private var cardBackgroundColor: Color { Color(hex: "FFFAF1") }
    private var textColor: Color { Color(hex: "38603E") }
    private var fieldBorderColor: Color { Color(hex: "CCDFD1") }
    private var fieldBackgroundColor: Color { Color(hex: "FFFFFF") }
    private var fieldTextColor: Color { Color(hex: "A8C2AE") }
    private var dottedDetailColor: Color { Color(hex: "EAFAEE") }

    // Match Create Collage button’s dotted border color
    private var buttonDottedDetailColor: Color { Color(hex: "113917") }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 20)

                VStack(spacing: 0) {
                    Spacer().frame(height: 10)

                    VStack(spacing: 0) {
                        CheckeredBorder(a: backgroundColor, b: cardBackgroundColor, count: 15, height: 12)

                        VStack(spacing: 24) {
                            // Top icon, same as Create Collage
                            Image("photo_stack_icon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 109, height: 82)
                                .foregroundColor(textColor)

                            Text("Join Collage")
                                .font(.custom("Sanchez", size: 28)).fontWeight(.bold)
                                .foregroundColor(textColor)

                            // Invite Code field (compact 39pt height, same field style)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Invite Code")
                                    .font(.custom("Sanchez", size: 18)).fontWeight(.bold)
                                    .foregroundColor(textColor)

                                HStack(spacing: 6) {
                                    FieldContainer(background: fieldBackgroundColor, border: fieldBorderColor) {
                                        ZStack(alignment: .leading) {
                                            if inviteCode.isEmpty {
                                                Text("Enter 8-character invite code")
                                                    .font(.custom("Sanchez", size: 16))
                                                    .foregroundColor(fieldTextColor)
                                                    .tracking(-0.5)
                                            }
                                            TextField("", text: $inviteCode)
                                                .font(.custom("Sanchez", size: 16))
                                                .foregroundColor(textColor)
                                                .tracking(-0.5)
                                                .textInputAutocapitalization(.characters)
                                                .autocorrectionDisabled()
                                                .onChange(of: inviteCode) {
                                                    // Uppercase and clamp to 8 chars
                                                    inviteCode = String(inviteCode.uppercased().prefix(8))
                                                }
                                        }
                                    }
                                    // dotted inner stroke to mirror Create Collage field box
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(dottedDetailColor, style: StrokeStyle(lineWidth: 2, dash: [4,4]))
                                            .padding(6)
                                    )
                                    .frame(maxWidth: 252)
                                    .frame(height: 39) // <-- compact height
                                }
                            }

                            Spacer().frame(height: 5)

                            if let error = errorMessage {
                                Text(error)
                                    .font(.custom("Sanchez", size: 14))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }

                            // CTA: Join Collage (matches Create Collage button style)
                            Button(action: joinCollage) {
                                ZStack {
                                    Image("blockbutton-blank-green")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .clipped()

                                    if isJoining {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Join Collage")
                                            .font(.custom("Sanchez", size: 18))
                                            .fontWeight(.bold)
                                            .foregroundColor(Color(hex: "FFFFFF")) // white text
                                            .offset(y: -5) // Move text up by 5px total
                                    }
                                }
                                .cornerRadius(12)
                            }
                            .disabled(inviteCode.count != 8 || isJoining)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        .background(cardBackgroundColor)

                        CheckeredBorder(a: backgroundColor, b: cardBackgroundColor, count: 15, height: 12)
                    }
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)
                    .padding(.horizontal, 16)

                    Spacer().frame(height: 10)
                }

                Spacer().frame(height: 33)
            }

            // Back arrow
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left")
                            .foregroundColor(textColor)
                            .font(.system(size: 24, weight: .medium))
                    }
                    .padding(.leading, 20)
                    .padding(.top, 10)
                    Spacer()
                }
                Spacer()
            }
        }
    }

    private func joinCollage() {
        errorMessage = nil
        isJoining = true
        Task {
            await appState.joinCollageWithInviteCode(inviteCode)
            await appState.loadCollageSessions()
            isJoining = false
            
            // Check if there was an error from AppState
            if let appError = appState.errorMessage {
                errorMessage = appError
            } else {
                dismiss()
            }
        }
    }
}


#Preview("Home Screen") {
    HomeScreenView()
        .environmentObject(AppState.shared)
}
