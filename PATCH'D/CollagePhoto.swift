import SwiftUI

// MARK: - CollagePhotoView

struct CollagePhotoView: View {
    let photo: CollagePhoto
    let viewSize: CGSize
    let state: CollageFullscreenView.PhotoState
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    let onMagnifyChanged: (MagnificationGesture.Value) -> Void
    let onMagnifyEnded: (MagnificationGesture.Value) -> Void
    let onRotationChanged: (RotationGesture.Value) -> Void
    let onRotationEnded: (RotationGesture.Value) -> Void
    
    var body: some View {
        AsyncImage(url: URL(string: photo.image_url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            case .failure:
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .foregroundColor(.gray)
            case .empty:
                ProgressView()
                    .frame(width: 200, height: 200)
            @unknown default:
                EmptyView()
            }
        }
        .scaleEffect(state.scale)
        .rotationEffect(state.rotation)
        .offset(state.offset)
        .position(
            x: CGFloat(photo.position_x) * viewSize.width,
            y: CGFloat(photo.position_y) * viewSize.height
        )
        .gesture(
            DragGesture()
                .onChanged(onDragChanged)
                .onEnded(onDragEnded)
        )
        .gesture(
            MagnificationGesture()
                .onChanged(onMagnifyChanged)
                .onEnded(onMagnifyEnded)
        )
        .gesture(
            RotationGesture()
                .onChanged(onRotationChanged)
                .onEnded(onRotationEnded)
        )
    }
}
