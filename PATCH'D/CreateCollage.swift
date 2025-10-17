import SwiftUI

// MARK: - Create Collage Sheet
struct CreateCollageSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var isCreating = false
    @State private var isPartyMode = false
    @State private var themeInput = ""
    @State private var selectedDuration: TimeInterval = 86400 // 1 day default for normal mode
    @State private var errorMessage: String?
    
    let normalDurationOptions: [(String, TimeInterval)] = [
        ("1 day", 86400),
        ("3 days", 259200),
        ("5 days", 432000),
        ("1 week", 604800)
    ]
    
    let partyDurationOptions: [(String, TimeInterval)] = [
        ("30 minutes", 1800),
        ("1 hour", 3600),
        ("2 hours", 7200),
        ("3 hours", 10800),
        ("5 hours", 18000)
    ]
    
    var currentDurationOptions: [(String, TimeInterval)] {
        isPartyMode ? partyDurationOptions : normalDurationOptions
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: isPartyMode ? "party.popper.fill" : "photo.stack.fill")
                        .font(.system(size: 60))
                        .foregroundColor(isPartyMode ? .purple : .green)
                        .animation(.easeInOut, value: isPartyMode)
                    
                    Text("Create a Collage")
                        .font(.title.bold())
                    
                    // Party Mode Toggle
                    HStack {
                        Image(systemName: isPartyMode ? "checkmark.square.fill" : "square")
                            .foregroundColor(isPartyMode ? .purple : .gray)
                            .font(.title2)
                        
                        Text("Party Mode Collage")
                            .font(.headline)
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            isPartyMode.toggle()
                            // Reset duration to first option when toggling modes
                            selectedDuration = currentDurationOptions[0].1
                            // Clear theme input when switching to party mode
                            if isPartyMode {
                                themeInput = ""
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    if isPartyMode {
                        Text("• Random theme assigned\n• Collaborators' images blurred until collage expires\n• Shorter durations")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("• Choose your own theme\n• All images visible to everyone\n• Longer durations")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Theme Input (only for non-party mode)
                    if !isPartyMode {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Theme / Title")
                                .font(.headline)
                            
                            TextField("Enter collage theme", text: $themeInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Duration Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration")
                            .font(.headline)
                        
                        Picker("Duration", selection: $selectedDuration) {
                            ForEach(currentDurationOptions, id: \.1) { option in
                                Text(option.0).tag(option.1)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
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
                    .background(isPartyMode ? Color.purple : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(isCreating || (!isPartyMode && themeInput.trimmingCharacters(in: .whitespaces).isEmpty))
                    .animation(.easeInOut, value: isPartyMode)
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func createCollage() {
        errorMessage = nil
        isCreating = true
        
        Task {
            do {
                let theme: String
                
                if isPartyMode {
                    // Fetch random theme for party mode
                    theme = try await appState.fetchRandomTheme()
                } else {
                    // Use user-entered theme for normal mode
                    theme = themeInput.trimmingCharacters(in: .whitespaces)
                }
                
                // Create collage with all parameters
                await appState.createNewCollageSession(
                    theme: theme,
                    duration: selectedDuration,
                    isPartyMode: isPartyMode
                )
                
                // Reload sessions
                await appState.loadCollageSessions()
                
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isCreating = false
        }
    }
}
