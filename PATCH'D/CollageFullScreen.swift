import SwiftUI
import PhotosUI
import UIKit

struct CollageFullscreenView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State var session: CollageSession
    
    @State private var draggedPhotoId: UUID?
    @State private var photoStates: [UUID: PhotoState] = [:]
    @State private var showImageSourcePicker = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var canvasSize: CGSize = .zero
    @State private var showStickerLibrary = false
    @State private var pasteErrorMessage: String?
    @State private var trashIconFrame: CGRect = .zero
    @State private var isOverTrash = false
    @State private var clearToolbar = false
    @State private var showMenuDropdown = false
    @State private var showCopyAlert = false
    @State private var showMembersList = false
    @State private var isExpired = false
    @State private var timeRemaining: TimeInterval = 0

    
    
    private var canvasBackground: some View {
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
    }
    
    private func collagePhotosView(_ geometry: GeometryProxy) -> some View {
        // Collage Canvas
        ZStack {
            ForEach(appState.collagePhotos) { photo in
                CollagePhotoView(
                    photo: photo,
                    viewSize: geometry.size,
                    state: photoStates[photo.id] ?? PhotoState(),
                    isBlurred: session.collage.isPartyMode && photo.user_id != appState.currentUser?.id,
                    isExpired: isExpired,
                    onDragChanged: { value in handleDragChanged(photo: photo, value: value, in: geometry) },
                    onDragEnded: { value in handleDragEnded(photo: photo, value: value, in: geometry) },
                    onMagnifyChanged: { value in handleMagnifyChanged(photo: photo, value: value) },
                    onMagnifyEnded: { _ in handleMagnifyEnded(photo: photo, in: geometry) },
                    onRotationChanged: { value in handleRotationChanged(photo: photo, value: value) },
                    onRotationEnded: { _ in handleRotationEnded(photo: photo, in: geometry) }
                )
            }
        }
       
    }
    
    // MARK: - Overlays

   private var copyAlertOverlay: some View {
       Group {
           if showCopyAlert {
               CopyAlertView()
                   .padding(.top, 100)
                   .transition(.move(edge: .top).combined(with: .opacity))
                   .animation(.easeInOut, value: showCopyAlert)
           }
       }
   }

    // MARK: - Lifecycle

    private func onAppear() {
        initializePhotoStates()
        Task { 
            await appState.loadCollageMembersForSession(collage_id: session.id)
            await appState.loadPhotosForSelectedSession()
        }
    }

    // MARK: - Toolbar Actions

    private func handleClose() {
        Task {
            clearToolbar = true
            
            // Navigate immediately for better UX
            await appState.deselectCollageSession(captureView: nil)
        }
    }

    private func handleCopyCode() {
        UIPasteboard.general.string = session.inviteCode
        showCopyAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopyAlert = false
        }
    }

    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // White background
                Color.white
                    .ignoresSafeArea()
                
                // Collage photos canvas
                collagePhotosView(geometry)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onAppear { canvasSize = geometry.size }
                    .onTapGesture(count: 2) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            clearToolbar.toggle()
                        }
                    }
                
                // Top-left: Close/Save button
                VStack {
                    HStack {
                        Button(action: handleClose) {
                            Image("icon-quit")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                        }
                        .padding(.leading, 20)
                        .padding(.top, 60) // Moved down to avoid dynamic island
                        
                        Spacer()
                    }
                    Spacer()
                }
                
                // Top center: Collage name and countdown timer
                VStack {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 8) {
                            // Collage name
                            Text(session.theme)
                                .font(.custom("Sanchez", size: 20))
                                .foregroundColor(Color.black)
                            
                            // Countdown timer
                            TimelineView(.periodic(from: Date(), by: 1.0)) { context in
                                let remaining = session.expiresAt.timeIntervalSince(context.date)
                                Text(formatTimeRemaining(remaining))
                                    .font(.custom("Sanchez", size: 12))
                                    .foregroundColor(Color.black)
                                    .onAppear {
                                        timeRemaining = remaining
                                        if remaining <= 0 {
                                            isExpired = true
                                        }
                                    }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 64) // Moved down 2px more from X icon and ellipsis icon
                    
                    Spacer()
                }
                
                // Top-right: Ellipsis menu and sticker button
                VStack {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            // Ellipsis menu button
                            Menu {
                                Button(action: { showImageSourcePicker = true }) {
                                    Label("Add Photo", systemImage: "plus")
                                }
                                Button(action: handleCopyCode) {
                                    Label("Copy Invite Code", systemImage: "document.on.document")
                                }
                                Button(action: { Task { await handlePasteAction(in: canvasSize) } }) {
                                    Label("Paste", systemImage: "doc.on.clipboard")
                                }
                            } label: {
                                Image("icon-ellipsis")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                            }
                            
                            // Sticker library button
                            Button(action: { showStickerLibrary = true }) {
                                Image("icon-sticker")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 60) // Moved down to avoid dynamic island
                    }
                    Spacer()
                }
                
                // Bottom-left: Collaborating users' profile avatars
                VStack {
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        Button(action: { showMembersList = true }) {
                            HStack(spacing: -6) {
                                ForEach(Array(appState.collageMembers.prefix(4).enumerated()), id: \.element.id) { index, member in
                                    RoundedRectangle(cornerRadius: 43.5)
                                        .fill(profileAvatarColor(for: index))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 43.5)
                                                .stroke(Color(hex: "FFF9F7"), lineWidth: 2)
                                        )
                                        .overlay(
                                            AsyncImage(url: URL(string: member.avatarUrl ?? "")) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } placeholder: {
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 20))
                                            }
                                            .frame(width: 46, height: 46)
                                            .clipShape(RoundedRectangle(cornerRadius: 43.5))
                                        )
                                        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)
                                }
                            }
                        }
                        .padding(.leading, 24)
                        .padding(.bottom, 24)
                        
                        Spacer()
                    }
                }
                
                // Bottom-right: Trash icon for photo removal (aligned with profile avatars)
                VStack {
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        Spacer()
                        
                        Image("icon-trash")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: isOverTrash ? 60 : 50, height: isOverTrash ? 60 : 50)
                            .foregroundColor(.black)
                        .background(
                            GeometryReader { geo in
                                Color.clear.onAppear {
                                    onTrashFrameChange(geo.frame(in: .global))
                                }
                                .onChange(of: geo.frame(in: .global)) { _, newFrame in
                                    onTrashFrameChange(newFrame)
                                }
                            }
                        )
                        .scaleEffect(isOverTrash ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: isOverTrash)
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .overlay(copyAlertOverlay, alignment: .top)
        .ignoresSafeArea(.all)
        .navigationBarHidden(true)
        .onAppear(perform: onAppear)
        .confirmationDialog("Add Photo", isPresented: $showImageSourcePicker) {
            Button("Take Photo") { showCamera = true }
            Button("Choose from Library") { showImagePicker = true }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showStickerLibrary) {
            StickerLibraryView { stickerURL in
                addStickerToCanvas(stickerURL: stickerURL, in: canvasSize)
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showMembersList) {
            MembersListView(members: appState.collageMembers)
                .environmentObject(appState)
        }
        .onChange(of: appState.photoUpdates.count) { _, _ in updatePhotoState() }
        .onChange(of: appState.collagePhotos.count) { _, _ in initializePhotoStates() }
        .onChange(of: selectedImage) { _, newValue in
            if let image = newValue { addPhotoToCanvas(image: image, in: canvasSize) }
        }
        .onChange(of: isExpired) { _, _ in handleExpired() }
        .alert("Paste Failed", isPresented: .constant(pasteErrorMessage != nil)) {
            Button("OK", role: .cancel) { pasteErrorMessage = nil }
        } message: {
            Text(pasteErrorMessage ?? "")
        }
    }
    
    private func handleExpired() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootView = window.rootViewController?.view {
            Task {
                await appState.captureExpiredSession(captureView: rootView)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func profileAvatarColor(for index: Int) -> Color {
        let colors = [
            Color(hex: "EB9982"), // Profile 1: Light peach/salmon
            Color(hex: "43170B"), // Profile 2: Dark brown
            Color(hex: "869BD2"), // Profile 3: Light blue/periwinkle
            Color(hex: "86D2A8")  // Profile 4: Light mint green
        ]
        return colors[index % colors.count]
    }
    
    private func onTrashFrameChange(_ frame: CGRect) {
        trashIconFrame = frame
    }
    
    // MARK: - Paste Handling
    private func handlePasteAction(in viewSize: CGSize) async {
        let pasteboard = UIPasteboard.general
        let centerPoint = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        if let image = pasteboard.image {
            addPhotoToCanvas(image: image, in: viewSize)
        } else if let data = pasteboard.data(forPasteboardType: "public.png") {
//            addPhotoToCanvas(image: image, in: viewSize)
            await appState.addPhotoFromPasteboard(at: centerPoint)
        } else {
            pasteErrorMessage = "No image found in clipboard. Try copying an image or cutout first."
        }
    }

    // MARK: - Helpers
    
    private func initializePhotoStates() {
        for photo in appState.collagePhotos {
            if photoStates[photo.id] == nil {
                // Convert normalized position to global coordinates
                let globalX = CGFloat(photo.position_x)
                let globalY = CGFloat(photo.position_y)
                
                photoStates[photo.id] = PhotoState(
                    rotation: Angle(degrees: photo.rotation),
                    scale: photo.scale,
                    lastRotation: Angle(degrees: photo.rotation),
                    lastScale: photo.scale,
                    globalPosition: CGPoint(x: globalX, y: globalY)
                )
            }
        }
    }
    
    private func updatePhotoState() {
        guard let uuid = appState.photoUpdates.popLast() else { return }
        
        guard let photo = appState.collagePhotos.filter({$0.id == uuid}).first else {
            photoStates[uuid] = nil
            return
        }
        
        guard var state = photoStates[uuid] else { return }
        
        state.globalPosition = CGPoint(x: CGFloat(photo.position_x), y: CGFloat(photo.position_y))
        state.rotation = Angle(degrees: photo.rotation)
        state.scale = photo.scale
        
        photoStates[uuid] = state
    }
    
    private func addPhotoToCanvas(image: UIImage, in viewSize: CGSize) {
        let centerPoint = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        
        Task {
//            await appState.addPhotoFromImage(image, at: centerPoint)
            let imageUrl = try await appState.uploadPhotoToStorage(image)
            guard let url = URL(string: imageUrl) else { return }
            await appState.addPhotoToCollage(url, at: centerPoint)
            selectedImage = nil
        }
    }
    
    private func addStickerToCanvas(stickerURL: String, in viewSize: CGSize) {
        guard let url = URL(string: stickerURL) else { return }
        
        Task {
            do {
                let (_, _) = try await URLSession.shared.data(from: url)
                let centerPoint = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
//                    await appState.addPhotoFromImage(image, at: centerPoint)
                await appState.addPhotoToCollage(url, at: centerPoint)
            } catch {
                print("Failed to download sticker: \(error)")
            }
        }
    }
    
    // MARK: - Gesture Handlers
    private func handleDragChanged(photo: CollagePhoto, value: DragGesture.Value, in geometry: GeometryProxy) {
        var state = photoStates[photo.id] ?? PhotoState()
        
        // Update offset
        state.offset = CGSize(
            width: state.lastOffset.width + value.translation.width,
            height: state.lastOffset.height + value.translation.height
        )
        
        // Calculate current global position
        let currentGlobalPosition = CGPoint(
            x: state.globalPosition.x + state.offset.width,
            y: state.globalPosition.y + state.offset.height
        )
        
        // Check if over trash
        let photoFrame = CGRect(
            x: currentGlobalPosition.x - 50,
            y: currentGlobalPosition.y - 50,
            width: 100,
            height: 100
        )
        
        isOverTrash = trashIconFrame.intersects(photoFrame)
        draggedPhotoId = photo.id
        
        photoStates[photo.id] = state
    }
    
    private func handleDragEnded(photo: CollagePhoto, value: DragGesture.Value, in geometry: GeometryProxy) {
        var state = photoStates[photo.id] ?? PhotoState()
        
        // Check if dropped on trash
        if isOverTrash {
            if photo.user_id == appState.currentUser?.id {
                Task {
                    await appState.deletePhoto(photo)
                }
            }
            isOverTrash = false
            draggedPhotoId = nil
            return
        }
        
        // Update global position
        state.globalPosition = CGPoint(
            x: state.globalPosition.x + state.offset.width,
            y: state.globalPosition.y + state.offset.height
        )
        state.offset = .zero
        state.lastOffset = .zero
        
        photoStates[photo.id] = state
        draggedPhotoId = nil
        isOverTrash = false
        
        Task {
            await appState.updatePhotoTransform(
                photo,
                position: state.globalPosition,
                rotation: state.rotation.degrees,
                scale: state.scale
            )
        }
    }
    
    private func handleMagnifyChanged(photo: CollagePhoto, value: MagnificationGesture.Value) {
        var state = photoStates[photo.id] ?? PhotoState()
        state.scale = state.lastScale * value
        photoStates[photo.id] = state
    }
    
    private func handleMagnifyEnded(photo: CollagePhoto, in geometry: GeometryProxy) {
        var state = photoStates[photo.id] ?? PhotoState()
        state.lastScale = state.scale
        photoStates[photo.id] = state
        
        Task {
            await appState.updatePhotoTransform(
                photo,
                position: state.globalPosition,
                rotation: state.rotation.degrees,
                scale: state.scale
            )
        }
    }
    
    private func handleRotationChanged(photo: CollagePhoto, value: RotationGesture.Value) {
        var state = photoStates[photo.id] ?? PhotoState()
        state.rotation = state.lastRotation + value
        photoStates[photo.id] = state
    }
    
    private func handleRotationEnded(photo: CollagePhoto, in geometry: GeometryProxy) {
        var state = photoStates[photo.id] ?? PhotoState()
        state.lastRotation = state.rotation
        photoStates[photo.id] = state
        
        Task {
            await appState.updatePhotoTransform(
                photo,
                position: state.globalPosition,
                rotation: state.rotation.degrees,
                scale: state.scale
            )
        }
    }
}

// MARK: - Copy Alert View
struct CopyAlertView: View {
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Invite code copied!")
                .foregroundColor(.white)
                .font(.subheadline)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
    }
}

// MARK: - Preview
#Preview("Collage FullScreen View") {
    CollageFullscreenView(session: CollageSession(
        id: UUID(),
        collage: Collage(
            id: UUID(),
            theme: "Sunset Vibes 🌅",
            createdBy: UUID(),
            inviteCode: "ABC123",
            startsAt: Date(),
            expiresAt: Date().addingTimeInterval(3600), // 1 hour from now
            createdAt: Date(),
            updatedAt: Date(),
            backgroundUrl: nil,
            previewUrl: nil,
            isPartyMode: false
        ),
        creator: CollageUser(
            id: UUID(),
            email: "creator@example.com",
            username: "Creator",
            avatarUrl: nil,
            createdAt: Date(),
            updatedAt: nil
        ),
        members: [
            CollageUser(
                id: UUID(),
                email: "user1@example.com",
                username: "User1",
                avatarUrl: nil,
                createdAt: Date(),
                updatedAt: nil
            ),
            CollageUser(
                id: UUID(),
                email: "user2@example.com",
                username: "User2",
                avatarUrl: nil,
                createdAt: Date(),
                updatedAt: nil
            ),
            CollageUser(
                id: UUID(),
                email: "user3@example.com",
                username: "User3",
                avatarUrl: nil,
                createdAt: Date(),
                updatedAt: nil
            ),
            CollageUser(
                id: UUID(),
                email: "user4@example.com",
                username: "User4",
                avatarUrl: nil,
                createdAt: Date(),
                updatedAt: nil
            )
        ],
        photos: []
    ))
    .environmentObject(AppState.preview())
}

#Preview("Collage FullScreen View - Party Mode") {
    CollageFullscreenView(session: CollageSession(
        id: UUID(),
        collage: Collage(
            id: UUID(),
            theme: "MYSTERY",
            createdBy: UUID(),
            inviteCode: "PARTY456",
            startsAt: Date(),
            expiresAt: Date().addingTimeInterval(1800), // 30 minutes from now
            createdAt: Date(),
            updatedAt: Date(),
            backgroundUrl: nil,
            previewUrl: nil,
            isPartyMode: true
        ),
        creator: CollageUser(
            id: UUID(),
            email: "partycreator@example.com",
            username: "PartyCreator",
            avatarUrl: nil,
            createdAt: Date(),
            updatedAt: nil
        ),
        members: [
            CollageUser(
                id: UUID(),
                email: "partyuser1@example.com",
                username: "PartyUser1",
                avatarUrl: nil,
                createdAt: Date(),
                updatedAt: nil
            ),
            CollageUser(
                id: UUID(),
                email: "partyuser2@example.com",
                username: "PartyUser2",
                avatarUrl: nil,
                createdAt: Date(),
                updatedAt: nil
            )
        ],
        photos: []
    ))
    .environmentObject(AppState.preview())
}


