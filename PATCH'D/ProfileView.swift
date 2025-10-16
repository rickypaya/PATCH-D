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
//                                        appState.updateUserAvatar(image)
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
                        
                        InfoRow(label: "Active Collages", value: "\(appState.collageSessions.count)")
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
                await appState.loadCurrentUser()
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
