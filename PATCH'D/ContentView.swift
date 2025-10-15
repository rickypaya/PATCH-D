//
//  ContentView.swift
//  PATCH'D
//  Ricardo Payares
//  Jericho Sanchez
//  Janice Chung
//  Yvette Luo
//
//| Table                  | Purpose                                                          |
//| ---------------------- | ---------------------------------------------------------------- |
//| `users`                | Stores registered user accounts (linked to Supabase Auth).       |
//| `collages`             | Represents a collage session (with theme, start/end time, etc.). |
//| `collage_members`      | Many-to-many relation between users and collages.                |
//| `photos`               | Stores uploaded photos placed within a collage.                  |
//| `themes`               | A pool of random themes fetched when a new collage is created.   |
//| `invites` *(optional)* | Stores shareable invite codes to join a collage.                 |
//
// Supabase storage buckets for photo uploads
//| Bucket           | Path Example                            | Access                           |
//| ---------------- | --------------------------------------- | -------------------------------- |
//| `collage-photos` | `/collages/{collage_id}/{photo_id}.jpg` | Public read, authenticated write |



import SwiftUI
import UIKit
import Combine

//MARK: - Default Avatar View (temporary)
func defaultMemberAvatar(for member: CollageUser) -> some View {
        Circle()
            .fill(Color.blue.opacity(0.7))
            .frame(width: 35, height: 35)
            .overlay(
                Text(member.username.prefix(1).uppercased())
                    .font(.caption.bold())
                    .foregroundColor(.white)
            )
            .overlay(
                Circle()
                    .stroke(Color.black, lineWidth: 2)
            )
    }

//MARK: - Main Content Flow Controller
struct ContentView: View {
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch appState.currentState {
            case .signUp:
                SignUpView()
            case .logIn:
                LogInView()
            case .profile:
                ProfileView()
            case .dashboard:
                DashboardView()
            }
        }
        .environmentObject(appState)
    }
}

//MARK: - Login View
struct LogInView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to PATCH'D")
                .font(.largeTitle.bold())
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Sign In") {
                Task { try await appState.signInWithEmail(email: email, password: password) }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

//MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to PATCH'D")
                .font(.largeTitle.bold())
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Sign Up") {
                Task {
                    print("Called sign up task")
                    try await appState.signUpWithEmail(email: email, password: password, username: username) }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Log In") {
                Task {
                    appState.currentState = .logIn
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

//MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var username: String = ""
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar Section
                    VStack(spacing: 16) {
                        ZStack {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .task {
                                        appState.updateUserAvatar(image)
                                    }
                            } else if let avatarUrl = appState.currentUser?.avatarUrl,
                                      let url = URL(string: avatarUrl), let user = appState.currentUser {
                                // Display existing avatar from URL
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                    case .failure(_), .empty:
                                        // Fallback to default avatar if loading fails
                                        defaultMemberAvatar(for: user)
                                    @unknown default:
                                        defaultMemberAvatar(for: user)
                                    }
                                }
                            } else {
                                // Default avatar with initial
                                let user = appState.currentUser
                                defaultMemberAvatar(for: user!)
                            }
                            
                            // Camera button overlay
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        showImagePicker = true
                                    }) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color.blue)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            .frame(width: 120, height: 120)
                        }
                        
                        Text("Tap to change photo")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Username Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            TextField("Username", text: $username)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(!isEditing)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            
                            Button(action: {
                                if isEditing {
                                    saveUsername()
                                } else {
                                    isEditing = true
                                }
                            }) {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                } else {
                                    Text(isEditing ? "Save" : "Edit")
                                        .foregroundColor(.blue)
                                }
                            }
                            .disabled(isSaving)
                            
                            if isEditing {
                                Button("Cancel") {
                                    username = appState.currentUser?.username ?? ""
                                    isEditing = false
                                    errorMessage = nil
                                }
                                .foregroundColor(.red)
                            }
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if let success = successMessage {
                            Text(success)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .background(Color.gray)
                        .padding(.horizontal)
                    
                    // Account Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account Information")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        InfoRow(label: "Email", value: "\(appState.currentUser!.email)")
                        
                        InfoRow(label: "Active Collages", value: "\(appState.activeSessions.count)")
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Sign Out Button
                    Button(action: {
                        Task { try await appState.signOut() }
                    }) {
                        Text("Sign Out")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        appState.currentState = .dashboard
                    }) {
                        HStack(spacing: 4) {
                            Text("Dashboard")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                username = appState.currentUser?.username ?? ""
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
    }
    
    func saveUsername() {
        guard appState.validateUserName(username) else {
            errorMessage = "Username must be 3-30 characters"
            return
        }
        
        guard username != appState.currentUser?.username else {
            isEditing = false
            return
        }
        
        isSaving = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                try await CollageDBManager.shared.updateUsername(username: username)
                try await appState.refreshUserProfile()
                successMessage = "Username updated successfully"
                isEditing = false
                
                // Clear success message after 2 seconds
                try await Task.sleep(nanoseconds: 2_000_000_000)
                successMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

//MARK: - Info Row Component
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

//MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

//MARK: - Dashboard View
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
                } else if appState.activeSessions.isEmpty {
                    EmptyStateView(showInviteCodeSheet: $showInviteCodeSheet, showCreateCollageSheet: $showCreateCollageSheet)
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
                await appState.refreshActiveSessions()
            }
        }
    }
}

//MARK: - Empty State View
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

//MARK: - Collage Grid View
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
                }
            }
            .padding()
        }
    }
}

//MARK: - Collage Preview Card
struct CollagePreviewCard: View {
    let session: CollageSession
    
    var body: some View {
        NavigationLink(destination: CollageDetailView(session: session)) {
            VStack(alignment: .leading, spacing: 8) {
                // Collage Preview Image
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(12)
                    
                    if session.photos.isEmpty {
                        VStack {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No photos yet")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        // Display photo thumbnails
                        AsyncImage(url: URL(string: session.photos.first?.imageUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .clipped()
                        .cornerRadius(12)
                        
                        if session.photos.count > 1 {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text("+\(session.photos.count - 1)")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(8)
                                        .padding(8)
                                }
                            }
                        }
                    }
                }
                
                // Theme
                Text(session.collage.theme)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Time remaining
                Text(timeRemainingText)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Members preview
                MembersPreview(members: session.members)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var timeRemainingText: String {
        let remaining = session.collage.expiresAt.timeIntervalSinceNow
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

//MARK: - Collage Detail View
struct CollageDetailView: View {
    let session: CollageSession
    @State private var showMembersList = false
    @State private var showCopiedAlert = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.collage.theme)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text(timeRemainingText)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Share code button
                        Button(action: {
                            UIPasteboard.general.string = session.inviteCode
                            showCopiedAlert = true
                            
                            // Hide alert after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showCopiedAlert = false
                            }
                        }) {
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
                        
                        // Members preview button
                        Button(action: {
                            showMembersList = true
                        }) {
                            HStack(spacing: -8) {
                                ForEach(session.members.prefix(3)) { member in
                                    defaultMemberAvatar(for: member)
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
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.bottom, 12)
                
                // Canvas Area
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    
                    if session.photos.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No photos yet")
                                .font(.title3)
                                .foregroundColor(.gray)
                            Text("Tap the button below to add your first photo")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        // TODO: Implement photo display on canvas
                        Text("Canvas with photos")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                // Bottom Button
                Button(action: {
                    // TODO: Implement add image
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Add Image")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding()
            }
            
            // Copied alert
            if showCopiedAlert {
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
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMembersList) {
            MembersListView(members: session.members)
        }
    }
    
    private var timeRemainingText: String {
        let remaining = session.collage.expiresAt.timeIntervalSinceNow
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
}

//MARK: - Members List View
struct MembersListView: View {
    let members: [CollageUser]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(members) { member in
                            HStack(spacing: 12) {
                                // Avatar
                                if let avatarUrl = member.avatarUrl, let url = URL(string: avatarUrl) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 50, height: 50)
                                                .clipShape(Circle())
                                        case .failure(_), .empty:
                                            defaultMemberAvatar(for: member)
                                        @unknown default:
                                            defaultMemberAvatar(for: member)
                                        }
                                    }
                                } else {
                                    defaultMemberAvatar(for: member)
                                }
                                
                                // Username
                                Text(member.username)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Members (\(members.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

//MARK: - Members Preview
struct MembersPreview: View {
    let members: [CollageUser]
    let maxDisplay = 3
    
    var body: some View {
        HStack(spacing: -8) {
            ForEach(members.prefix(maxDisplay)) { member in
                memberAvatarView(for: member)
            }
            
            if members.count > maxDisplay {
                Circle()
                    .fill(Color.gray.opacity(0.7))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Text("+\(members.count - maxDisplay)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                    )
            }
            
            Spacer()
            
            Text("\(members.count) member\(members.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.leading, 4)
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
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                        )
                case .failure(_), .empty:
                    defaultMemberAvatar(for: member)
                @unknown default:
                    defaultMemberAvatar(for: member)
                }
            }
        } else {
            defaultMemberAvatar(for: member)
        }
    }
}

//MARK: - Invite Code Sheet
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
    
    func joinCollage() {
        errorMessage = nil
        isJoining = true
        
        Task {
            do {
                let session = try await CollageDBManager.shared.joinCollageByInviteCode(inviteCode: inviteCode)
                await appState.refreshActiveSessions()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isJoining = false
        }
    }
}

//MARK: - Create Collage Sheet
struct CreateCollageSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var isCreating = false
    @State private var selectedDuration: TimeInterval = 3600 // 1 hour default
    @State private var errorMessage: String?
    
    let durationOptions: [(String, TimeInterval)] = [
        ("30 minutes", 1800),
        ("1 hour", 3600),
        ("2 hours", 7200),
        ("6 hours", 21600),
        ("12 hours", 43200),
        ("24 hours", 86400)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Create a Collage")
                    .font(.title.bold())
                
                Text("A random theme will be assigned")
                    .font(.body)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration")
                        .font(.headline)
                    
                    Picker("Duration", selection: $selectedDuration) {
                        ForEach(durationOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Button(action: createCollage) {
                    if isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Collage")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(isCreating)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    func createCollage() {
        errorMessage = nil
        isCreating = true
        
        Task {
            do {
                // Fetch random theme
                let theme = try await CollageDBManager.shared.fetchRandomTheme()
                
                // Create collage
                let session = try await CollageDBManager.shared.createCollage(
                    theme: theme,
                    duration: selectedDuration
                )
                
                await appState.refreshActiveSessions()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isCreating = false
        }
    }
}


#Preview {
    ContentView()
}
