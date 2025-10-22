import SwiftUI

struct ArchiveSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Archive View")
                    .font(.title.bold())
                
                Text("A List of your past collages")
                    .font(.body)
                    .foregroundColor(.gray)
                
                let columns = [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ]
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(appState.archive) { session in
                            RealCollagePreviewCard(session: session)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}
