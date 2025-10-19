import SwiftUI
import PhotosUI
import UIKit

struct CollageFullscreenView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    let session: CollageSession
    
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
                        onCopyCode: { UIPasteboard.general.string = session.inviteCode   },
                        onAddSticker: { showStickerLibrary = true },
                        onPaste: {
                            Task {
                                await handlePasteAction(in: canvasSize)
                            }
                        },
                        onAddPhoto: { showImageSourcePicker = true },
                        clearToolbar: clearToolbar
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
                        clearToolbar: clearToolbar
                    )
                }
            },
            alignment: .bottom
        )
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

// MARK: - Top Toolbar View
struct TopToolbarView: View {
    let onClose: () -> Void
    let onCopyCode: () -> Void
    let onAddSticker: () -> Void
    let onPaste: () -> Void
    let onAddPhoto: () -> Void
    let clearToolbar: Bool
    
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
                
                // Add Sticker Button
                Button(action: onAddSticker) {
                    Image("stickerIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.purple.opacity(0.8))
                        .clipShape(Circle())
                }
                
                //Copy Invite Button
                Button(action: onCopyCode) {
                    Image(systemName: "document.on.document")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.blue.opacity(0.8))
                        .clipShape(Circle())
                }
                
                // Paste Button
                Button(action: onPaste) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.green.opacity(0.8))
                        .clipShape(Circle())
                }
                
                // Add Photo Button
                Button(action: onAddPhoto) {
                    Image(systemName: "plus")
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
    let clearToolbar: Bool
    
    var body: some View {
        HStack(alignment: .bottom) {
            // Active Members List
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(members) { member in
                        VStack(spacing: 4) {
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
                            
                            Text(member.username)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
            
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
