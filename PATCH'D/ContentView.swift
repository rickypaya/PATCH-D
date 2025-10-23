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

//MARK: - Main Content Flow Controller
struct ContentView: View {
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        ZStack {
            switch appState.currentState {
            case .onboardingTitle:
                OnboardingTitleView()
            case .onboardingWelcome:
                OnboardingWelcome_SignUporLogInView()
            case .onboardingSignUp:
                OnboardingSignUpView()
            case .onboardingSignIn:
                OnboardingSignInView()
            case .registrationSuccess:
                RegistrationSuccessView()
            case .onboarding1:
                Onboarding1View()
            case .onboarding2:
                Onboarding2View()
            case .onboarding3:
                Onboarding3View()
            case .onboarding4:
                Onboarding4View()
            case .homeScreen:
                HomeScreenView()
            case .homeCollageCarousel:
                HomeScreenView()
            case .createCollage:
                CreateCollageView()
            case .profile:
                ProfileView()
            case .dashboard:
                HomeScreenView()
            case .fullscreen:
                CollageFullscreenView(session: appState.selectedSession!)
            case .friendsList:
                FriendsListView()
            case .collageInvites:
                CollageInvitesListView()
            case .final:
                FinalCollageView(session: appState.selectedSession!)
            }
        }
        .animation(.easeIn, value: appState.currentState)
        .environmentObject(appState)
    }
}


#Preview {
    ContentView()
}
