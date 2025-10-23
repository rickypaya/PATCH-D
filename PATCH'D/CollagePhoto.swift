import SwiftUI

//// MARK: - Collage Photo View (Updated)
struct CollagePhotoView: View {
    let photo: CollagePhoto
    let viewSize: CGSize
    let state: PhotoState
    let isBlurred: Bool
    let isExpired: Bool
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    let onMagnifyChanged: (MagnificationGesture.Value) -> Void
    let onMagnifyEnded: (MagnificationGesture.Value) -> Void
    let onRotationChanged: (RotationGesture.Value) -> Void
    let onRotationEnded: (RotationGesture.Value) -> Void
    
    var body: some View {
        AsyncImage(url: URL(string: photo.image_url)) { image in
            image
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .blur(radius: !isExpired && isBlurred ? 20 : 0)
                .overlay(
                    isBlurred && !isExpired ?
                    Image(systemName: "lock.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.8))
                    : nil
                )
        } placeholder: {
            ProgressView()
                .frame(width: 150, height: 150)
        }
        .animation(.easeInOut, value: isBlurred)
        .rotationEffect(state.rotation)
        .scaleEffect(state.scale)
        .offset(state.offset)
        .position(state.globalPosition)
        .gesture(
            DragGesture()
                .onChanged(onDragChanged)
                .onEnded(onDragEnded)
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged(onMagnifyChanged)
                .onEnded(onMagnifyEnded)
        )
        .simultaneousGesture(
            RotationGesture()
                .onChanged(onRotationChanged)
                .onEnded(onRotationEnded)
        )
    }
}
