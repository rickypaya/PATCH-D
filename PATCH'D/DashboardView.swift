import SwiftUI

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showInviteCodeSheet = false
    @State private var showCreateCollageSheet = false
    @State private var showArchiveSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gray.ignoresSafeArea()
                
                if appState.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if appState.activeSessions.isEmpty {
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
                        Button (action: {
                            showArchiveSheet = true
                        }) {
                        Label("View Archive", systemImage: "archivebox")
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
            .sheet(isPresented: $showArchiveSheet) {
                ArchiveSheet()
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
                ForEach(appState.activeSessions) { session in
                    CollagePreviewCard(session: session)
                        .onTapGesture {
                            Task {
                                await appState.selectCollageSession(session)
                                
                                try? await Task.sleep(nanoseconds: 200_000_000)
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
    @State var preview_url: String?
    
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
        .background(Color.black.opacity(0.7))
        .cornerRadius(16)
        .onAppear{
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
            await appState.joinCollageWithInviteCode(inviteCode)
            await appState.loadCollageSessions()
            try? await Task.sleep(nanoseconds: 100_000_000)
            dismiss()
            isJoining = false
        }
    }
}
