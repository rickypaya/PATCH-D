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
            case .fullscreen:
                CollageFullscreenView(session: appState.selectedSession!)
            }
        }
        .animation(.easeIn, value: appState.currentState)
        .environmentObject(appState)
    }
}


#Preview {
    ContentView()
}
