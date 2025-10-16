import SwiftUI

// MARK: - Collage Detail View
struct CollageDetailView: View {
    @EnvironmentObject var appState: AppState
    let session: CollageSession
    
    @State private var showMembersList = false
    @State private var showCopiedAlert = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Header
                headerView
                    .padding(.bottom, 12)
                
                Spacer()
                
                previewImageView
                    .frame(width: 169, height: 300)
                
                Spacer()
                
                // Action Buttons
                actionButtonsView
                    .padding()
            }
            
            // Copied Alert Overlay
            if showCopiedAlert {
                copiedAlertView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMembersList) {
            MembersListView(members: session.members)
        }
        
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.theme)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(timeRemainingText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Share Code Button
            shareCodeButton
            
            // Members Button
            membersButton
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var shareCodeButton: some View {
        Button(action: copyInviteCode) {
            VStack(spacing: 4) {
                Image(systemName: "square.on.square")
                    .font(.system(size: 20))
                Text(session.inviteCode)
                    .font(.caption.bold())
            }
            .foregroundColor(.blue)
            .padding(8)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
        }
    }
    
    private var membersButton: some View {
        Button(action: { showMembersList = true }) {
            HStack(spacing: -8) {
                ForEach(session.members.prefix(3)) { member in
                    memberAvatarView(for: member)
                }
                
                if session.members.count > 3 {
                    Circle()
                        .fill(Color.gray.opacity(0.7))
                        .frame(width: 35, height: 35)
                        .overlay(
                            Text("+\(session.members.count - 3)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                        )
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            Button(action: {
                Task {
                    await appState.selectCollageSession(session)
                }
            }) {
                Label("Open Canvas", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Copied Alert
    private var copiedAlertView: some View {
        VStack {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Invite code copied!")
                    .font(.subheadline.bold())
            }
            .padding()
            .background(Color.gray.opacity(0.9))
            .cornerRadius(12)
            .padding(.top, 50)
            
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: showCopiedAlert)
    }
    
    // MARK: - Helper Functions
    private func copyInviteCode() {
        UIPasteboard.general.string = session.inviteCode
        showCopiedAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedAlert = false
        }
    }
    
    @ViewBuilder
    private func memberAvatarView(for member: CollageUser) -> some View {
        if let avatarUrl = member.avatarUrl, let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 35, height: 35)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                case .failure(_), .empty:
                    defaultAvatar(for: member)
                @unknown default:
                    defaultAvatar(for: member)
                }
            }
        } else {
            defaultAvatar(for: member)
        }
    }
    
    private func defaultAvatar(for member: CollageUser) -> some View {
        Circle()
            .fill(Color.blue.opacity(0.7))
            .frame(width: 35, height: 35)
            .overlay(
                Text(String(member.username.prefix(1)).uppercased())
                    .font(.caption.bold())
                    .foregroundColor(.white)
            )
            .overlay(Circle().stroke(Color.black, lineWidth: 2))
    }
    
    private var timeRemainingText: String {
        let remaining = session.expiresAt.timeIntervalSinceNow
        if remaining <= 0 {
            return "Expired"
        }
        
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
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
                _ = try await CollageDBManager.shared.joinCollageByInviteCode(inviteCode: inviteCode)
                await appState.loadCollageSessions()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isJoining = false
        }
    }
}
