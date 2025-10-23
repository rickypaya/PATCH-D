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

    struct PhotoState {
        var offset: CGSize = .zero
        var rotation: Angle = .zero
        var scale: CGFloat = 1.0
        var lastOffset: CGSize = .zero
        var lastRotation: Angle = .zero
        var lastScale: CGFloat = 1.0
        var globalPosition: CGPoint = .zero
    }
    
    var body: some View {
        GeometryReader { geometry in
            // Main Canvas Layer
            ZStack {
                Color.gray.opacity(0.2)
                    .ignoresSafeArea()
                
                // Collage Canvas
                ZStack {
                    ForEach(appState.collagePhotos) { photo in
                        CollagePhotoView(
                            photo: photo,
                            viewSize: geometry.size,
                            state: photoStates[photo.id] ?? PhotoState(),
                            isBlurred: session.collage.isPartyMode && photo.user_id != appState.currentUser?.id,
                            onDragChanged: { value in handleDragChanged(photo: photo, value: value, in: geometry) },
                            onDragEnded: { value in handleDragEnded(photo: photo, value: value, in: geometry) },
                            onMagnifyChanged: { value in handleMagnifyChanged(photo: photo, value: value) },
                            onMagnifyEnded: { _ in handleMagnifyEnded(photo: photo, in: geometry) },
                            onRotationChanged: { value in handleRotationChanged(photo: photo, value: value) },
                            onRotationEnded: { _ in handleRotationEnded(photo: photo, in: geometry) }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onAppear {
                    canvasSize = geometry.size
                }
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        clearToolbar.toggle()
                    }
                }
            }
        }
        .overlay(
            // Top Toolbar Overlay (hidden when saving)
            Group {
                if !clearToolbar {
                    TopToolbarView(
                        onClose: {
                            Task {
                                // Set saving state to hide overlays
                                clearToolbar = true
                                
                                // Small delay to allow UI to update
                                try? await Task.sleep(nanoseconds: 100_000_000)
                                
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = windowScene.windows.first,
                                   let rootView = window.rootViewController?.view {
                                    await appState.deselectCollageSession(captureView: rootView)
                                }
                                
                                dismiss()
                            }
                        },
                        onCopyCode: {
                            UIPasteboard.general.string = session.inviteCode
                            showCopyAlert = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showCopyAlert = false
                            }
                        },
                        onAddSticker: { showStickerLibrary = true },
                        onPaste: {
                            Task {
                                await handlePasteAction(in: canvasSize)
                            }
                        },
                        onAddPhoto: { showImageSourcePicker = true },
                        showMenuDropdown: $showMenuDropdown,
                        clearToolbar: clearToolbar,
                        session: session,
                        expirationDate: session.expiresAt
                    )
                }
            },
            alignment: .top
        )
        .overlay(
            // Bottom Toolbar Overlay (hidden when saving)
            Group {
                if !clearToolbar {
                    BottomToolbarView(
                        members: appState.collageMembers,
                        isOverTrash: isOverTrash,
                        onTrashFrameChange: { frame in
                            trashIconFrame = frame
                        },
                        onMembersPressed: { showMembersList = true },
                        clearToolbar: clearToolbar
                    )
                }
            },
            alignment: .bottom
        )
        .overlay(alignment: .top) {
            if showCopyAlert {
                CopyAlertView()
                    .padding(.top, 100)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: showCopyAlert)
            }
        }
        .ignoresSafeArea(.all)
        .navigationBarHidden(true)
        .onAppear {
            initializePhotoStates()
            Task {
                await appState.loadCollageMembersForSession(collage_id: session.id)
            }
        }
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
        .onChange(of: appState.photoUpdates.count) { _, _ in
            updatePhotoState()
        }
        .onChange(of: appState.collagePhotos.count) { _, _ in
            // Initialize photo states for any new photos
            for photo in appState.collagePhotos {
                if photoStates[photo.id] == nil {
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
        .onChange(of: selectedImage) { _, newValue in
            if let image = newValue {
                addPhotoToCanvas(image: image, in: canvasSize)
            }
        }
        .alert("Paste Failed", isPresented: .constant(pasteErrorMessage != nil)) {
            Button("OK", role: .cancel) { pasteErrorMessage = nil }
        } message: {
            Text(pasteErrorMessage ?? "")
        }
        .sheet(isPresented: $showMembersList) {
            MembersListView(members: appState.collageMembers)
        }
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
                let (data, _) = try await URLSession.shared.data(from: url)
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

// MARK: - Top Toolbar View
struct TopToolbarView: View {
    let onClose: () -> Void
    let onCopyCode: () -> Void
    let onAddSticker: () -> Void
    let onPaste: () -> Void
    let onAddPhoto: () -> Void
    @Binding var showMenuDropdown: Bool
    let clearToolbar: Bool
    let session: CollageSession
    let expirationDate: Date
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            HStack {
                // Close Button
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                VStack {
                    Text(session.theme)
                        .font(.system(size: 24))
                    
                    TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1.0)) { context in
                        Text(expirationDate, style: .timer)
                            .font(.subheadline)
                            .onAppear {
                                
                                if context.date >= expirationDate {
                                    //navigate to fullscreen view
                                }
                            }
                    }
                }
                
                Spacer()
                
                // Menu Button
                Menu {
                    Button(action: onAddSticker) {
                        Label("Add Sticker", systemImage: "face.smiling")
                    }
                    
                    Button(action: onCopyCode) {
                        Label("Copy Invite Code", systemImage: "document.on.document")
                    }
                    
                    Button(action: onPaste) {
                        Label("Paste", systemImage: "doc.on.clipboard")
                    }
                    
                    Button(action: onAddPhoto) {
                        Label("Add Photo", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.blue.opacity(0.8))
                        .clipShape(Circle())
                }
            }
            .padding()
            .frame(height: 120)
        }
        .padding(.top, 16)
    }
}

// MARK: - Bottom Toolbar View
struct BottomToolbarView: View {
    let members: [CollageUser]
    let isOverTrash: Bool
    let onTrashFrameChange: (CGRect) -> Void
    let onMembersPressed: () -> Void
    let clearToolbar: Bool
    
    var body: some View {
        HStack(alignment: .bottom) {
            // Active Members Preview (limited to 3)
            Button(action: onMembersPressed) {
                HStack(spacing: -8) {
                    ForEach(members.prefix(3)) { member in
                        AsyncImage(url: URL(string: member.avatarUrl ?? "")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                    
                    // Show count if more than 3 members
                    if members.count > 3 {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.8))
                                .frame(width: 40, height: 40)
                            
                            Text("+\(members.count - 3)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                }
                .padding(.horizontal, 16)
            }
            
            Spacer()
            
            // Trash Icon for Delete
            ZStack {
                Circle()
                    .fill(isOverTrash ? Color.red.opacity(0.9) : Color.red.opacity(0.6))
                    .frame(width: 60, height: 60)
                
                Image(systemName: isOverTrash ? "trash.fill" : "trash")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
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
            .padding(.trailing, 16)
            .scaleEffect(isOverTrash ? 1.2 : 1.0)
            .animation(.spring(response: 0.3), value: isOverTrash)
        }
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
            .ignoresSafeArea(edges: .bottom)
        )
    }
}
