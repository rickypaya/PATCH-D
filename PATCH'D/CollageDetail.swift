//
//  CollageDetail.swift
//  PATCH'D
//
//  Created by Ricardo Payares on 10/15/25.
//

import SwiftUI
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
                    await appState.loadCollageSessions()
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                }
                isJoining = false
            }
        }
    }

