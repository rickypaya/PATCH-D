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


    struct PhotoState {
        var offset: CGSize = .zero
        var rotation: Angle = .zero
        var scale: CGFloat = 1.0
        var lastOffset: CGSize = .zero
        var lastRotation: Angle = .zero
        var lastScale: CGFloat = 1.0
    }
    
    var body: some View {
        GeometryReader { geometry in
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
                            onDragChanged: { value in handleDragChanged(photo: photo, value: value) },
                            onDragEnded: { value in handleDragEnded(photo: photo, value: value, in: geometry.size) },
                            onMagnifyChanged: { value in handleMagnifyChanged(photo: photo, value: value) },
                            onMagnifyEnded: { _ in handleMagnifyEnded(photo: photo, in: geometry.size) },
                            onRotationChanged: { value in handleRotationChanged(photo: photo, value: value) },
                            onRotationEnded: { _ in handleRotationEnded(photo: photo, in: geometry.size) }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onAppear { canvasSize = geometry.size }
                
                // Top Bar with Close, Paste, and Add buttons
                VStack {
                    HStack {
                        // Close Button
                        Button(action: {
                            Task {
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = windowScene.windows.first,
                                   let rootView = window.rootViewController?.view {
                                    await appState.deselectCollageSession(captureView: rootView)
                                    
                                    try await Task.sleep(nanoseconds: UInt64(5) * 1_000_000_000)
                                }
                                dismiss()
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // add sticker button
                        Button(action: {
                            showStickerLibrary = true
                        }) {
                            // Use your custom sticker icon from Assets
                            Image("stickerIcon")  // Replace with your actual asset name
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.purple.opacity(0.8))
                                .clipShape(Circle())
                        }
                        // Paste Button
                        Button(action: {
                            handlePasteAction(in: geometry.size)
                        }) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.green.opacity(0.8))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 8)
                        
                        // Add Photo Button
                        Button(action: {
                            showImageSourcePicker = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.blue.opacity(0.8))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { initializePhotoStates() }
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
    private func handlePasteAction(in viewSize: CGSize) {
        let pasteboard = UIPasteboard.general
        
        if let image = pasteboard.image {
            // Directly pasted UIImage (like a cutout from Photos)
            addPhotoToCanvas(image: image, in: viewSize)
        } else if let data = pasteboard.data(forPasteboardType: "public.png"),
                  let image = UIImage(data: data) {
            // Fallback if the pasteboard contains PNG data
            addPhotoToCanvas(image: image, in: viewSize)
        } else {
            pasteErrorMessage = "No image found in clipboard. Try copying an image or cutout first."
        }
    }
    
    // MARK: - Helpers
    
    private func initializePhotoStates() {
        for photo in appState.collagePhotos {
            if photoStates[photo.id] == nil {
                photoStates[photo.id] = PhotoState(
                    rotation: Angle(degrees: photo.rotation),
                    scale: photo.scale,
                    lastRotation: Angle(degrees: photo.rotation),
                    lastScale: photo.scale
                )
            }
        }
    }
    
    private func addPhotoToCanvas(image: UIImage, in viewSize: CGSize) {
        let centerPoint = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        
        Task {
            await appState.addPhotoFromImage(image, at: centerPoint, in: viewSize)
            selectedImage = nil
        }
    }
    private func addStickerToCanvas(stickerURL: String, in viewSize: CGSize) {
        // Download the sticker image
        guard let url = URL(string: stickerURL) else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                if let image = UIImage(data: data) {
                    // Add sticker at center of screen
                    let centerPoint = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
                    
                    await appState.addPhotoFromImage(image, at: centerPoint, in: viewSize)
                }
            } catch {
                print("Failed to download sticker: \(error)")
            }
        }
    }
    
    // MARK: - Gesture Handlers
    private func handleDragChanged(photo: CollagePhoto, value: DragGesture.Value) {
        var state = photoStates[photo.id] ?? PhotoState()
        state.offset = CGSize(
            width: state.lastOffset.width + value.translation.width,
            height: state.lastOffset.height + value.translation.height
        )
        photoStates[photo.id] = state
    }
    
    private func handleDragEnded(photo: CollagePhoto, value: DragGesture.Value, in viewSize: CGSize) {
        var state = photoStates[photo.id] ?? PhotoState()
        state.lastOffset = state.offset
        photoStates[photo.id] = state
        
        let position = calculateAbsolutePosition(photo: photo, state: state, in: viewSize)
        
        Task {
            await appState.updatePhotoTransform(photo, position: position,
                                                rotation: state.rotation.degrees,
                                                scale: state.scale, in: viewSize)
        }
    }
    
    private func handleMagnifyChanged(photo: CollagePhoto, value: MagnificationGesture.Value) {
        var state = photoStates[photo.id] ?? PhotoState()
        state.scale = state.lastScale * value
        photoStates[photo.id] = state
    }
    
    private func handleMagnifyEnded(photo: CollagePhoto, in viewSize: CGSize) {
        var state = photoStates[photo.id] ?? PhotoState()
        state.lastScale = state.scale
        photoStates[photo.id] = state
        let position = calculateAbsolutePosition(photo: photo, state: state, in: viewSize)
        Task {
            await appState.updatePhotoTransform(photo, position: position,
                                                rotation: state.rotation.degrees,
                                                scale: state.scale, in: viewSize)
        }
    }
    
    private func handleRotationChanged(photo: CollagePhoto, value: RotationGesture.Value) {
        var state = photoStates[photo.id] ?? PhotoState()
        state.rotation = state.lastRotation + value
        photoStates[photo.id] = state
    }
    
    private func handleRotationEnded(photo: CollagePhoto, in viewSize: CGSize) {
        var state = photoStates[photo.id] ?? PhotoState()
        state.lastRotation = state.rotation
        photoStates[photo.id] = state
        let position = calculateAbsolutePosition(photo: photo, state: state, in: viewSize)
        Task {
            await appState.updatePhotoTransform(photo, position: position,
                                                rotation: state.rotation.degrees,
                                                scale: state.scale, in: viewSize)
        }
    }
    
    private func calculateAbsolutePosition(photo: CollagePhoto, state: PhotoState, in viewSize: CGSize) -> CGPoint {
        let baseX = CGFloat(photo.position_x) * viewSize.width
        let baseY = CGFloat(photo.position_y) * viewSize.height
        return CGPoint(x: baseX + state.offset.width, y: baseY + state.offset.height)
    }
}
