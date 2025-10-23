import SwiftUI
import Photos

struct FinalCollageView: View {
    @EnvironmentObject var appState: AppState
    @State var session: CollageSession
    @State private var isDownloading = false
    @State private var downloadComplete = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background image
            if let previewUrl = session.collage.previewUrl, !previewUrl.isEmpty {
                AsyncImage(url: URL(string: previewUrl)) { phase in
                    switch phase {
                    case .empty:
                        Color.black
                            .overlay {
                                ProgressView()
                                    .tint(.white)
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Color.black
                            .overlay {
                                VStack {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("Failed to load image")
                                        .foregroundColor(.gray)
                                        .padding(.top, 8)
                                }
                            }
                    @unknown default:
                        Color.black
                    }
                }
            } else {
                Color.black
            }
            
            // Info card at bottom
            VStack {
                Spacer()
                
                HStack(alignment: .center, spacing: 16) {
                    // Left side: Theme and details
                    VStack(alignment: .leading, spacing: 8) {
                        Text(session.collage.theme)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            if session.collage.isPartyMode {
                                HStack(spacing: 4) {
                                    Image(systemName: "party.popper.fill")
                                        .font(.caption)
                                    Text("Party Mode")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.purple)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                Text(formattedDate)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Right side: Download button
                    Button(action: downloadCollage) {
                        ZStack {
                            Circle()
                                .fill(downloadComplete ? Color.green : Color.blue)
                                .frame(width: 56, height: 56)
                            
                            if isDownloading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: downloadComplete ? "checkmark" : "arrow.down.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(isDownloading || downloadComplete)
                }
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            
            // Close button overlay
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        appState.currentState = .profile
                    }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.trailing, 20)
                }
                
                Spacer()
            }
        }
        .ignoresSafeArea()
        .alert("Download Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: session.collage.expiresAt)
    }
    
    private func downloadCollage() {
        Task {
            isDownloading = true
            
            do {
                try await appState.downloadCollagePreview(session: session)
                
                await MainActor.run {
                    downloadComplete = true
                    isDownloading = false
                    
                    // Reset download complete after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        downloadComplete = false
                    }
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
