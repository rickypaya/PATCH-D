import SwiftUI

//MARK: - Members List View
struct MembersListView: View {
    let members: [CollageUser]
    @Environment(\.dismiss) var dismiss
    @State var inviteFriends = false
    @State var inviteCode: String = "" // Add this if not passed from parent
    @EnvironmentObject var appState: AppState
    
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
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundColor(.gray)
                                                .frame(width: 50, height: 50)
                                        @unknown default:
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundColor(.gray)
                                                .frame(width: 50, height: 50)
                                        }
                                    }
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray)
                                        .frame(width: 50, height: 50)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Invite Friends") {
                        inviteFriends = true
                    }
                    .foregroundColor(.blue)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $inviteFriends) {
                InviteFriendsSheet(inviteCode: $inviteCode)
                    .environmentObject(appState)
            }
        }
    }
}

struct InviteFriendsSheet : View {
    @Binding var inviteCode: String
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    private var fileredFriends: [CollageUser] {
        appState.friends.filter { friend in
            !appState.collageMembers.contains(where: {$0.id == friend.id})
        }
    }
    
    var body : some View {
        NavigationView {
            ScrollView {
                if fileredFriends.isEmpty {
                    EmptyStateView(
                        icon: "person.2.slash",
                        title: fileredFriends.isEmpty ? "No Friends Yet" : "",
                        message: fileredFriends.isEmpty ? "Add friends to start creating collages together!" : ""
                    )
                    .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(fileredFriends) { friend in
                            InviteCard(
                                user: friend,
                                inviteFriend: {
                                    Task {
                                        guard let collageId = appState.selectedSession?.collage.id else {
                                            return
                                        }
                                        await appState.sendCollageInvite(collageId: collageId, to: friend.id)
                                    }
                            })
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("Invite friends to collage")
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

struct InviteCard: View {
    let user: CollageUser
    let inviteFriend: () -> Void
    @State private var friendshipId: UUID?
    @State private var isInvited: Bool = false
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            UserAvatarView(user: user, size: 50)
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.custom("Sanchez", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text(user.email)
                    .font(.custom("Sanchez", size: 14))
                    .foregroundColor(.black.opacity(0.6))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Invite button
            Button(action: {
                inviteFriend()
                withAnimation {
                    isInvited = true
                }
            }) {
                if isInvited {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Invited")
                            .font(.custom("Sanchez", size: 14))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(20)
                } else {
                    Image(systemName: "plus.app")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .disabled(isInvited)
        }
        .padding(15)
        .background(Color.white.opacity(0.9))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
