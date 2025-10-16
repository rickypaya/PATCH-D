//
//  DashboardView.swift
//  PATCH'D
//
//  Created by Ricardo Payares on 10/15/25.
//

import SwiftUI
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
                } else if appState.collageSessions.isEmpty {
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
                await appState.loadCollageSessions()
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
                ForEach(appState.collageSessions) { session in
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
//                        AsyncImage(url: URL(string: session.photos.first?.imageUrl ?? "")) { image in
//                            image
//                                .resizable()
//                                .aspectRatio(contentMode: .fill)
//                        } placeholder: {
//                            Color.gray.opacity(0.3)
//                        }
//                        .clipped()
//                        .cornerRadius(12)
                        
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
                await appState.createNewCollageSession(duration: selectedDuration)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isCreating = false
        }
    }
}
