import SwiftUI
import Photos

struct FinalCollageView: View {
    @EnvironmentObject var appState: AppState
    @State var session: CollageSession
    @State private var isDownloading = false
    @State private var downloadComplete = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Collage preview background (majority of screen)
                if let previewUrl = session.collage.previewUrl, !previewUrl.isEmpty {
                    AsyncImage(url: URL(string: previewUrl)) { phase in
                        switch phase {
                        case .empty:
                            Color.black
                                .overlay {
                                    ProgressView()
                                        .tint(.white)
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height * 5/6) // 5/6 of screen
                                .clipped()
                                .ignoresSafeArea(.all) // Fill all the way to top
                        case .failure:
                            Color.black
                                .overlay {
                                    VStack {
                                        Image(systemName: "photo.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.gray)
                                        Text("Failed to load image")
                                            .foregroundColor(.gray)
                                            .padding(.top, 8)
                                    }
                                }
                        @unknown default:
                            Color.black
                        }
                    }
                } else {
                    Color.black
                        .frame(width: geometry.size.width, height: geometry.size.height * 5/6)
                }
                
                // Top-left: Exit button
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                appState.navigateToHome()
                            }
                        }) {
                            Image("icon-quit")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                        }
                        .padding(.leading, 20)
                        .padding(.top, 60) // Below dynamic island
                        
                        Spacer()
                    }
                    Spacer()
                }
                
                // Bottom section: Final Collage title section (1/6 of screen)
                VStack {
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 16) {
                        // Left side: Title and date
                        VStack(alignment: .leading, spacing: 8) {
                            Text(session.collage.theme)
                                .font(.custom("Sanchez", size: 20))
                                .foregroundColor(Color.black)
                            
                            Text(formattedCompletionDate)
                                .font(.custom("Sanchez", size: 12))
                                .foregroundColor(Color.black)
                        }
                        
                        Spacer()
                        
                        // Right side: Download button
                        Button(action: downloadCollage) {
                            ZStack {
                                if isDownloading {
                                    ProgressView()
                                        .tint(.black)
                                        .scaleEffect(0.8)
                                } else {
                                    Image("icon-save")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(downloadComplete ? .green : .black)
                                }
                            }
                        }
                        .disabled(isDownloading || downloadComplete)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(hex: "EEDDC1")) // Background color for title section
                    .frame(height: geometry.size.height * 1/6) // 1/6 of screen height
                }
            }
        }
        .ignoresSafeArea()
        .alert("Download Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var formattedCompletionDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: session.collage.expiresAt)
    }
    
    private func downloadCollage() {
        Task {
            isDownloading = true
            
            do {
                try await appState.downloadCollagePreview(session: session)
                
                await MainActor.run {
                    downloadComplete = true
                    isDownloading = false
                    
                    // Reset download complete after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        downloadComplete = false
                    }
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Final Collage View - New Design") {
    FinalCollageView(session: CollageSession(
        id: UUID(),
        collage: Collage(
            id: UUID(),
            theme: "Sunset Vibes 🌅",
            createdBy: UUID(),
            inviteCode: "ABC123",
            startsAt: Date(),
            expiresAt: Date().addingTimeInterval(3600), // 1 hour from now
            createdAt: Date(),
            updatedAt: Date(),
            backgroundUrl: nil,
            previewUrl: "https://picsum.photos/400/600", // Sample preview image
            isPartyMode: false
        ),
        creator: CollageUser(
            id: UUID(),
            email: "creator@example.com",
            username: "Creator",
            avatarUrl: nil,
            createdAt: Date(),
            updatedAt: nil
        ),
        members: [
            CollageUser(
                id: UUID(),
                email: "user1@example.com",
                username: "User1",
                avatarUrl: nil,
                createdAt: Date(),
                updatedAt: nil
            ),
            CollageUser(
                id: UUID(),
                email: "user2@example.com",
                username: "User2",
                avatarUrl: nil,
                createdAt: Date(),
                updatedAt: nil
            ),
            CollageUser(
                id: UUID(),
                email: "user3@example.com",
                username: "User3",
                avatarUrl: nil,
                createdAt: Date(),
                updatedAt: nil
            )
        ],
        photos: []
    ))
    .environmentObject(AppState.preview())
}

#Preview("Final Collage View - Party Mode") {
    FinalCollageView(session: CollageSession(
        id: UUID(),
        collage: Collage(
            id: UUID(),
            theme: "Night Out 🌃", // Random party theme
            createdBy: UUID(),
            inviteCode: "PARTY456",
            startsAt: Date(),
            expiresAt: Date().addingTimeInterval(1800), // 30 minutes from now
            createdAt: Date(),
            updatedAt: Date(),
            backgroundUrl: nil,
            previewUrl: "https://picsum.photos/400/600", // Sample preview image
            isPartyMode: true
        ),
        creator: CollageUser(
            id: UUID(),
            email: "partycreator@example.com",
            username: "PartyCreator",
            avatarUrl: nil,
            createdAt: Date(),
            updatedAt: nil
        ),
        members: [
            CollageUser(
                id: UUID(),
                email: "partyuser1@example.com",
                username: "PartyUser1",
                avatarUrl: nil,
                createdAt: Date(),
                updatedAt: nil
            ),
            CollageUser(
                id: UUID(),
                email: "partyuser2@example.com",
                username: "PartyUser2",
                avatarUrl: nil,
                createdAt: Date(),
                updatedAt: nil
            )
        ],
        photos: []
    ))
    .environmentObject(AppState.preview())
}

#Preview("Final Collage View - No Preview Image") {
    FinalCollageView(session: CollageSession(
        id: UUID(),
        collage: Collage(
            id: UUID(),
            theme: "Coffee Shop Moments ☕",
            createdBy: UUID(),
            inviteCode: "COFFEE789",
            startsAt: Date(),
            expiresAt: Date().addingTimeInterval(7200), // 2 hours from now
            createdAt: Date(),
            updatedAt: Date(),
            backgroundUrl: nil,
            previewUrl: nil, // No preview image - shows fallback
            isPartyMode: false
        ),
        creator: CollageUser(
            id: UUID(),
            email: "coffeecreator@example.com",
            username: "CoffeeCreator",
            avatarUrl: nil,
            createdAt: Date(),
            updatedAt: nil
        ),
        members: [
            CollageUser(
                id: UUID(),
                email: "coffeeuser1@example.com",
                username: "CoffeeUser1",
                avatarUrl: nil,
                createdAt: Date(),
                updatedAt: nil
            )
        ],
        photos: []
    ))
    .environmentObject(AppState.preview())
}
