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


//MARK: - Login View
//TODO: - Signup View
struct AuthenticationView: View {
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
                Task { await appState.signIn(email: email, password: password) }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

//MARK: - Dashboard View shows all the current collages someone is apart of. Maybe a dock to see
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            VStack {
                if appState.activeSessions.isEmpty {
                    Text("No active collages yet.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(appState.activeSessions) { session in
                        Button {
                            appState.selectedSession = session
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(session.theme)
                                        .font(.headline)
                                    Text("Expires in \(session.endTime.timeIntervalSinceNow / 60, specifier: "%.0f") min")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                
                HStack {
                    Button("➕ Create Collage") {
                        Task { await appState.createNewCollage() }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("🔗 Join Collage") {
                        withAnimation {
                            appState.joinCode = ""
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Your Collages")
        }
        .sheet(item: $appState.selectedSession) { session in
            CollageView(session: session)
        }
        .sheet(isPresented: Binding(get: { !appState.joinCode.isEmpty }, set: { _ in })) {
            JoinCollageView()
        }
    }
}

//MARK: - Join Collage View
struct JoinCollageView: View {
    @EnvironmentObject var appState: AppState
    @State private var code = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Invite Code")
                .font(.title2)
            
            TextField("Invite Code", text: $code)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button("Join") {
                Task { await appState.joinCollage(code: code) }
                appState.joinCode = ""
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

//MARK: - Collage View
struct CollageView: View {
    let session: CollageSession
    @State private var showCamera = false
    @State private var userPhotos: [CollagePhoto] = []
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                ZStack {
                    ForEach(session.photos) { photo in
                        AsyncImage(url: URL(string: photo.imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .position(photo.position)
                                .blur(radius: shouldBlur(photo: photo) ? 20 : 0)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }
            }
            
            VStack {
                Spacer()
                Button {
                    showCamera = true
                } label: {
                    Label("Add Photo", systemImage: "camera.fill")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding()
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraView { image in
                // TODO: random crop + upload logic
            }
        }
        .navigationTitle(session.theme)
    }
    
    func shouldBlur(photo: CollagePhoto) -> Bool {
        // Blur all photos that aren't this user's before expiry
        let isExpired = Date() > session.endTime
        if isExpired { return false }
        guard let userId = AppState.shared.currentUserId else { return true }
        return photo.userId != userId
    }
}

//MARK: - Camera View
struct CameraView: View {
    var onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Camera Placeholder")
                .font(.headline)
                .padding()
            
            Button("Simulate Capture") {
                let sampleImage = UIImage(systemName: "photo")!
                onCapture(sampleImage)
                dismiss()
            }
        }
    }
}

//MARK: - Main Content Flow Controller
struct ContentView: View {
    @StateObject var appState = AppState.shared
    
    var body: some View {
        Group {
            if appState.showAuth {
                AuthenticationView()
            } else {
                DashboardView()
            }
        }
        .environmentObject(appState)
    }
}

#Preview {
    ContentView()
}
