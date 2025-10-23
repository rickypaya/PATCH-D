//
//  CollageInvitesListView.swift
//  PATCH'D
//
//  Displays pending collage invites with sender info and accept/reject actions
//

import SwiftUI

struct CollageInvitesListView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white,
                    Color(red: 1.0, green: 0.98, blue: 0.9),
                    Color(red: 1.0, green: 0.95, blue: 0.85)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topNavigationBar
                
                ScrollView {
                    if appState.pendingCollageInvites.isEmpty {
                        EmptyStateView(
                            icon: "tray",
                            title: "No Collage Invites",
                            message: "You're all caught up!"
                        )
                        .padding(.top, 100)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(appState.pendingCollageInvites, id: \.invite.id) { invite in
                                CollageInviteCard(invite: invite)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 50)
                    }
                }
            }
            
            // Loading overlay
            if appState.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.yellow)
            }
        }
        .onAppear {
            Task {
                await appState.loadPendingCollageInvites()
            }
        }
    }
    
    // MARK: - Top Bar
    private var topNavigationBar: some View {
        HStack {
            Button(action: {
                appState.currentState = .profile
            }) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                    )
            }
            
            Spacer()
            
            Text("Collage Invites")
                .font(.custom("Sanchez", size: 24))
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Spacer()
            
            Circle()
                .fill(Color.clear)
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

// MARK: - Collage Invite Card
struct CollageInviteCard: View {
    @EnvironmentObject var appState: AppState
    let invite: (invite: CollageInvite, collage: Collage, sender: CollageUser)
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            UserAvatarView(user: invite.sender, size: 50)
            
            // Invite Info
            VStack(alignment: .leading, spacing: 4) {
                Text(invite.sender.username)
                    .font(.custom("Sanchez", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                HStack(spacing: 5) {
                    Text("invited you to:")
                        .font(.custom("Sanchez", size: 14))
                        .foregroundColor(.black.opacity(0.6))
                    
                    Text(invite.collage.theme)
                        .font(.custom("Sanchez", size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                }
                
                if invite.collage.isPartyMode {
                    Label("Party Mode!", systemImage: "sparkles")
                        .font(.custom("Sanchez", size: 12))
                        .foregroundColor(.purple)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 10) {
                // Accept
                Button(action: {
                    Task {
                        await appState.acceptCollageInvite(invite.invite.id)
                    }
                }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.green)
                        .clipShape(Circle())
                }
                
                // Reject
                Button(action: {
                    Task {
                        await appState.rejectCollageInvite(invite.invite.id)
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
        }
        .padding(15)
        .background(Color.white.opacity(0.9))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    CollageInvitesListView()
        .environmentObject(AppState.preview())
}
