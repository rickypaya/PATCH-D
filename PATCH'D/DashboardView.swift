import SwiftUI

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showInviteCodeSheet = false
    @State private var showCreateCollageSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if appState.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if appState.collageSessions.isEmpty {
                    EmptyStateView(
                        showInviteCodeSheet: $showInviteCodeSheet,
                        showCreateCollageSheet: $showCreateCollageSheet
                    )
                } else {
                    CollageGridView()
                }
            }
            .navigationTitle("Your Collages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        appState.currentState = .profile
                    }) {
                        Image(systemName: "person.circle")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showCreateCollageSheet = true
                        }) {
                            Label("Create Collage", systemImage: "plus.square")
                        }
                        
                        Button(action: {
                            showInviteCodeSheet = true
                        }) {
                            Label("Join with Code", systemImage: "link")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showInviteCodeSheet) {
                InviteCodeSheet()
            }
            .sheet(isPresented: $showCreateCollageSheet) {
                CreateCollageSheet()
            }
            .refreshable {
                await appState.loadCollageSessions()
            }
        }
        .onAppear {
            if appState.currentUser == nil {
                appState.currentState = .signUp
            }
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    @Binding var showInviteCodeSheet: Bool
    @Binding var showCreateCollageSheet: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Active Collages")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Create a new collage or join one with an invite code")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            HStack(spacing: 16) {
                Button(action: {
                    showCreateCollageSheet = true
                }) {
                    Label("Create", systemImage: "plus.square")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    showInviteCodeSheet = true
                }) {
                    Label("Join", systemImage: "link")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Collage Grid View
struct CollageGridView: View {
    @EnvironmentObject var appState: AppState
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(appState.collageSessions) { session in
                    CollagePreviewCard(session: session)
                        .onTapGesture {
                            Task {
                                await appState.selectCollageSession(session)
                            }
                        }
                        
                }
            }
            .padding()
        }
    }
}

// MARK: - Collage Preview Card
struct CollagePreviewCard: View {
    let session: CollageSession
    
    var body: some View {
      

        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                // Collage Preview Image
                previewImageView
                
                Group {
                    // Theme
                    Text(session.theme)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Time Remaining
                    Text(timeRemainingText)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Members Count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(session.members.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(16)
                }
                .padding(4)
                
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color.gray.opacity(0.7))
        .cornerRadius(16)
        
    }
    
    private var previewImageView: some View {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(12)
                
                if let previewUrl = session.preview_url, let url = URL(string: previewUrl) {
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
                    
                    // Photo count badge
                    if !session.photos.isEmpty {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("\(session.photos.count) photo\(session.photos.count == 1 ? "" : "s")")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(8)
                                    .padding(8)
                            }
                        }
                    }
                } else {
                    emptyPreviewView
                }
            }
        }
        
        private var emptyPreviewView: some View {
            VStack(spacing: 8) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text("No photos yet")
                    .font(.caption)
                    .foregroundColor(.gray)
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
