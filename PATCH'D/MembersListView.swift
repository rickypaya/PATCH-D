//
//  MembersListView.swift
//  PATCH'D
//
//  Created by Ricardo Payares on 10/15/25.
//

import SwiftUI

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
                                                .frame(width: 35, height: 35)
                                        @unknown default:
                                            defaultMemberAvatar(for: member)
                                                .frame(width: 35, height: 35)
                                        }
                                    }
                                } else {
                                    defaultMemberAvatar(for: member)
                                        .frame(width: 35, height: 35)
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
