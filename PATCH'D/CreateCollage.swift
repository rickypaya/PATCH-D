import SwiftUI

// MARK: - Create Collage View
struct CreateCollageView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var isCreating = false
    @State private var themeInput = ""
    @State private var inviteCodeInput = ""
    @State private var selectedDuration: TimeInterval = 1800 // 30 min default (Party Mode)
    @State private var errorMessage: String?
    @State private var showValidationError = false
    @State private var isPartyMode = false
    @State private var showThemeDropdown = false
    @State private var selectedThemeIndex: Int? = nil
    
    let durationOptions: [(String, TimeInterval)] = [
        ("1 Day", 86400),
        ("3 Days", 259200),
        ("5 Days", 432000)
    ]
    
    let partyDurationOptions: [(String, TimeInterval)] = [
        ("30 min", 1800),
        ("1 hour", 3600),
        ("2 hours", 7200),
        ("3 hours", 10800),
        ("5 hours", 18000)
    ]
    
    let predefinedThemes = [
        "Sunset Vibes 🌅",
        "Coffee Shop Moments ☕",
        "Fit Check 👟",
        "Food Tour 🍕",
        "Night Out 🌃",
        "Beach Day 🏖️",
        "Concert & Festival 🎵",
        "Pet Time 🐾",
        "Travel Adventures ✈️",
        "Gym & Wellness 💪",
        "Brunch Squad 🥞",
        "Road Trip 🚗",
        "Nature Escape 🌿",
        "Thrift Finds 🛍️",
        "Game Night 🎮"
    ]
    
    // MARK: - Theme Colors
    private var neonTheme: (background: Color, cardBg: Color, text: Color, accent: Color, border: Color, shadow: Color) {
        (
            background: Color(red: 0.0, green: 0.0, blue: 0.067), // 000011
            cardBg: Color(red: 0.102, green: 0.102, blue: 0.180), // 1a1a2e
            text: Color(red: 0.0, green: 1.0, blue: 1.0), // 00ffff
            accent: Color(red: 1.0, green: 0.0, blue: 1.0), // ff00ff
            border: Color(red: 0.0, green: 1.0, blue: 1.0), // 00ffff
            shadow: Color(red: 0.0, green: 1.0, blue: 1.0).opacity(0.3)
        )
    }
    
    private var currentTheme: (background: Color, cardBg: Color, text: Color, accent: Color, border: Color, shadow: Color) {
        isPartyMode ? neonTheme : regularTheme
    }
    
    private var regularTheme: (background: Color, cardBg: Color, text: Color, accent: Color, border: Color, shadow: Color) {
        (
            background: Color(red: 0.949, green: 0.882, blue: 0.780), // F2E1C7
            cardBg: Color(red: 1.0, green: 0.898, blue: 0.0), // FFE500
            text: Color.black,
            accent: Color(red: 0.220, green: 0.376, blue: 0.243), // 38603E
            border: Color.black,
            shadow: Color.black.opacity(0.2)
        )
    }
    
    private var isFormValid: Bool {
        !themeInput.trimmingCharacters(in: .whitespaces).isEmpty || 
        !inviteCodeInput.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var buttonStyle: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(currentTheme.border, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
    }
    
    private var durationCircleStyle: some View {
        Circle()
            .stroke(currentTheme.border, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
    }
    
    // MARK: - Computed Views
    private var topNavigationBar: some View {
        HStack {
            // Profile icon
            Button(action: {
                withAnimation(.easeInOut(duration: 0.5)) {
                    appState.currentState = .profile
                }
            }) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                    )
            }
            
            Spacer()
            
            // Center logo
            Image("Patch'd_logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 30)
            
            Spacer()
            
            // Hamburger menu
            Menu {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        appState.currentState = .homeScreen
                    }
                }) {
                    Label("Back to Home", systemImage: "house")
                }
            } label: {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .zIndex(10)
    }
    
    private var themeInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isPartyMode ? "Theme" : "Choose a theme")
                .font(.custom("Sanchez", size: 18))
                .fontWeight(.bold)
                .foregroundColor(currentTheme.text)
                .animation(.easeInOut(duration: 0.5), value: isPartyMode)
            
            if isPartyMode {
                // Party Mode: Show mystery box emojis
                Text("Theme randomly generated 🎲")
                    .font(.custom("Sanchez", size: 16))
                    .foregroundColor(currentTheme.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(currentTheme.cardBg)
                    .overlay(buttonStyle)
                    .cornerRadius(8)
                    .animation(.easeInOut(duration: 0.5), value: isPartyMode)
            } else {
                HStack {
                    TextField("Name your collage or pick one", text: $themeInput)
                        .font(.custom("Sanchez", size: 16))
                        .foregroundColor(currentTheme.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .overlay(buttonStyle)
                        .cornerRadius(8)
                        .onTapGesture {
                            // Clear selected theme when user starts typing
                            if selectedThemeIndex != nil {
                                selectedThemeIndex = nil
                            }
                        }
                    
                    // Dropdown arrow button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showThemeDropdown.toggle()
                        }
                    }) {
                        Image(systemName: showThemeDropdown ? "chevron.up" : "chevron.down")
                            .foregroundColor(currentTheme.text)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 30, height: 30)
                            .background(Color.white)
                            .overlay(
                                Circle()
                                    .stroke(currentTheme.border, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                            )
                            .cornerRadius(15)
                    }
                    .padding(.leading, 8)
                }
            }
        }
    }
    
    private var inviteCodeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isPartyMode ? "Visibility" : "Joining a collage?")
                .font(.custom("Sanchez", size: 18))
                .fontWeight(.bold)
                .foregroundColor(currentTheme.text)
                .animation(.easeInOut(duration: 0.5), value: isPartyMode)
            
            if isPartyMode {
                // Party Mode: Show blurred image emojis
                Text("Photos stay blurred until reveal 👀")
                    .font(.custom("Sanchez", size: 16))
                    .foregroundColor(currentTheme.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(currentTheme.cardBg)
                    .overlay(buttonStyle)
                    .cornerRadius(8)
                    .animation(.easeInOut(duration: 0.5), value: isPartyMode)
            } else {
                TextField("Enter invite code", text: $inviteCodeInput)
                    .font(.custom("Sanchez", size: 16))
                    .foregroundColor(currentTheme.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .overlay(buttonStyle)
                    .cornerRadius(8)
                    .animation(.easeInOut(duration: 0.5), value: isPartyMode)
            }
        }
    }
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isPartyMode ? "Party duration (expires in:)" : "Duration (expires in:)")
                .font(.custom("Sanchez", size: 18))
                .fontWeight(.bold)
                .foregroundColor(currentTheme.text)
                .animation(.easeInOut(duration: 0.5), value: isPartyMode)
            
            HStack(spacing: 12) {
                ForEach(isPartyMode ? partyDurationOptions : durationOptions, id: \.1) { option in
                    Button(action: {
                        selectedDuration = option.1
                    }) {
                        Text(option.0)
                            .font(.custom("Sanchez", size: isPartyMode ? 10 : 14))
                            .fontWeight(.bold)
                            .foregroundColor(currentTheme.text)
                            .frame(width: isPartyMode ? 50 : 60, height: isPartyMode ? 50 : 60)
                            .background(
                                Circle()
                                    .fill(selectedDuration == option.1 ? 
                                          (isPartyMode ? 
                                           currentTheme.accent : // Original magenta accent for Party Mode
                                           Color(red: 0.769, green: 0.875, blue: 0.769)) : // C4DFC4 for regular mode
                                          (isPartyMode ? currentTheme.cardBg : Color.white))
                            )
                            .overlay(durationCircleStyle)
                            .animation(.easeInOut(duration: 0.5), value: isPartyMode)
                    }
                }
            }
        }
    }
    
    private var partyModeSection: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isPartyMode.toggle()
                }
            }) {
                Text(isPartyMode ? "☑️" : "☐")
                    .font(.system(size: 20))
                    .foregroundColor(currentTheme.text)
            }
            
            Text(isPartyMode ? "Party Mode" : "Try Party Mode?")
                .font(.custom("Sanchez", size: 16))
                .fontWeight(.bold)
                .italic()
                .foregroundColor(currentTheme.text)
            
            Spacer()
        }
    }
    
    private var validationErrorSection: some View {
        Group {
            if showValidationError && !isFormValid {
                Text("Pick a theme or join a collage to get started!")
                    .font(.custom("Sanchez", size: 14))
                    .foregroundColor(isPartyMode ? neonTheme.accent : .red)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.5), value: isPartyMode)
            }
        }
    }
    
    private var startCollagingButton: some View {
        Button(action: handleStartCollaging) {
            Text(isPartyMode ? "Start the Party 🎉" : "Start Collaging")
                .font(.custom("Sanchez", size: 18))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(currentTheme.accent)
                .cornerRadius(12)
                .shadow(color: currentTheme.shadow, radius: 4, x: 0, y: 2)
                .animation(.easeInOut(duration: 0.5), value: isPartyMode)
        }
        .disabled(isCreating)
    }
    
    private var dropdownOverlay: some View {
        Group {
            if showThemeDropdown {
                dropdownContent
            }
        }
    }
    
    private var dropdownContent: some View {
        ZStack {
            // Semi-transparent background to dim the rest of the UI
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showThemeDropdown = false
                    }
                }
            
            dropdownModal
        }
        .zIndex(1000) // Ensure it appears on top
    }
    
    private var dropdownModal: some View {
        VStack(spacing: 0) {
            dropdownHeader
            dropdownScrollableList
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    private var dropdownHeader: some View {
        HStack {
            Text("Choose a Theme")
                .font(.custom("Sanchez", size: 18))
                .fontWeight(.bold)
                .foregroundColor(.black)
            Spacer()
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showThemeDropdown = false
                }
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
    }
    
    private var dropdownScrollableList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(predefinedThemes.enumerated()), id: \.offset) { index, theme in
                    dropdownThemeRow(index: index, theme: theme)
                }
            }
        }
        .frame(maxHeight: 300) // Limit height for scrolling
        .background(Color.white)
    }
    
    private func dropdownThemeRow(index: Int, theme: String) -> some View {
        Button(action: {
            themeInput = theme
            selectedThemeIndex = index
            withAnimation(.easeInOut(duration: 0.3)) {
                showThemeDropdown = false
            }
        }) {
            HStack {
                Text(theme)
                    .font(.custom("Sanchez", size: 16))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                Spacer()
                if selectedThemeIndex == index {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var body: some View {
        ZStack {
            // Dynamic background color based on theme
            currentTheme.background.ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: isPartyMode)
            
            VStack {
                topNavigationBar
                
                Spacer()
                
                // Main popup content
                VStack(spacing: 24) {
                    // Title
                    Text(isPartyMode ? "🎉 Create a Party Collage" : "Create a Collage")
                        .font(.custom("Sanchez", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(currentTheme.text)
                        .animation(.easeInOut(duration: 0.5), value: isPartyMode)
                    
                    themeInputSection
                    inviteCodeSection
                    durationSection
                    partyModeSection
                    validationErrorSection
                    startCollagingButton
                }
                .padding(32)
                .background(currentTheme.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(currentTheme.border, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                        .padding(1)
                )
                .cornerRadius(20)
                .shadow(color: currentTheme.shadow, radius: 4, x: 0, y: 2)
                .animation(.easeInOut(duration: 0.5), value: isPartyMode)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            
            dropdownOverlay
        }
    }
    
    private func handleStartCollaging() {
        showValidationError = true
        
        if !isFormValid {
            return
        }
        
        isCreating = true
        errorMessage = nil
        
        Task {
            if !inviteCodeInput.trimmingCharacters(in: .whitespaces).isEmpty {
                // Join existing collage with invite code
                await appState.joinCollageWithInviteCode(inviteCodeInput.trimmingCharacters(in: .whitespaces))
                
            } else {
                // Create new collage with theme
                let theme: String
                if isPartyMode {
                    // Use random theme for Party Mode
                    theme = predefinedThemes.randomElement() ?? "Party Time 🎉"
                } else {
                    // Use user input theme for regular mode
                    theme = themeInput.trimmingCharacters(in: .whitespaces)
                }
                
                await appState.createNewCollageSession(
                    theme: theme,
                    duration: selectedDuration,
                    isPartyMode: isPartyMode
                )
            }
            
            // Reload sessions
            await appState.loadCollageSessions()
            
            dismiss()
            DispatchQueue.main.async {
                isCreating = false
            }
        }
    }
}

// MARK: - Legacy CreateCollageSheet (for backward compatibility)
struct CreateCollageSheet: View {
    var body: some View {
        CreateCollageView()
    }
}

// MARK: - Preview
#Preview("Create Collage View") {
    CreateCollageView()
        .environmentObject(AppState.shared)
}

#Preview("Create Collage View - Party Mode") {
    CreateCollageView()
        .environmentObject(AppState.shared)
        .onAppear {
            // Simulate Party Mode being enabled
        }
}

// MARK: - Create Collage Party Mode View
struct CreateCollage_PartyModeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var showRegularView = false
    @State private var isCreating = false
    @State private var selectedDuration: TimeInterval = 1800 // 30 min default
    @State private var errorMessage: String?
    
    let partyDurationOptions: [(String, TimeInterval)] = [
        ("30 min", 1800),
        ("1 hour", 3600),
        ("2 hours", 7200),
        ("3 hours", 10800),
        ("5 hours", 18000)
    ]
    
    let predefinedThemes = [
        "Sunset Vibes 🌅",
        "Coffee Shop Moments ☕",
        "Fit Check 👟",
        "Food Tour 🍕",
        "Night Out 🌃",
        "Beach Day 🏖️",
        "Concert & Festival 🎵",
        "Pet Time 🐾",
        "Travel Adventures ✈️",
        "Gym & Wellness 💪",
        "Brunch Squad 🥞",
        "Road Trip 🚗",
        "Nature Escape 🌿",
        "Thrift Finds 🛍️",
        "Game Night 🎮"
    ]
    
    // MARK: - Neon Theme Colors
    private var neonTheme: (background: Color, cardBg: Color, text: Color, accent: Color, border: Color, shadow: Color) {
        (
            background: Color(red: 0.0, green: 0.0, blue: 0.067), // 000011
            cardBg: Color(red: 0.102, green: 0.102, blue: 0.180), // 1a1a2e
            text: Color(red: 0.0, green: 1.0, blue: 1.0), // 00ffff
            accent: Color(red: 1.0, green: 0.0, blue: 1.0), // ff00ff
            border: Color(red: 0.0, green: 1.0, blue: 1.0), // 00ffff
            shadow: Color(red: 0.0, green: 1.0, blue: 1.0).opacity(0.3)
        )
    }
    
    private var neonButtonStyle: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(neonTheme.border, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
    }
    
    private var neonDurationCircleStyle: some View {
        Circle()
            .stroke(neonTheme.border, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
    }
    
    // MARK: - Computed Views
    private var topNavigationBar: some View {
        HStack {
            // Profile icon
            Button(action: {
                withAnimation(.easeInOut(duration: 0.5)) {
                    appState.currentState = .profile
                }
            }) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                    )
            }
            
            Spacer()
            
            // Center logo
            Image("Patch'd_logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 30)
            
            Spacer()
            
            // Hamburger menu
            Menu {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        appState.currentState = .homeScreen
                    }
                }) {
                    Label("Back to Home", systemImage: "house")
                }
            } label: {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .zIndex(10)
    }
    
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Theme")
                .font(.custom("Sanchez", size: 18))
                .fontWeight(.bold)
                .foregroundColor(neonTheme.text)
            
            Text("Theme randomly generated 🎲")
                .font(.custom("Sanchez", size: 16))
                .foregroundColor(neonTheme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(neonTheme.cardBg)
                .overlay(neonButtonStyle)
                .cornerRadius(8)
        }
    }
    
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photos stay blurred until reveal 👀")
                .font(.custom("Sanchez", size: 18))
                .fontWeight(.bold)
                .foregroundColor(neonTheme.text)
            
            Text("Photos stay blurred until reveal 👀")
                .font(.custom("Sanchez", size: 16))
                .foregroundColor(neonTheme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(neonTheme.cardBg)
                .overlay(neonButtonStyle)
                .cornerRadius(8)
        }
    }
    
    private var partyDurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Party duration (expires in:)")
                .font(.custom("Sanchez", size: 18))
                .fontWeight(.bold)
                .foregroundColor(neonTheme.text)
            
            HStack(spacing: 12) {
                ForEach(partyDurationOptions, id: \.1) { option in
                    Button(action: {
                        selectedDuration = option.1
                    }) {
                        Text(option.0)
                            .font(.custom("Sanchez", size: 12))
                            .fontWeight(.bold)
                            .foregroundColor(neonTheme.text)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(selectedDuration == option.1 ? 
                                          neonTheme.accent : 
                                          neonTheme.cardBg)
                            )
                            .overlay(neonDurationCircleStyle)
                    }
                }
            }
        }
    }
    
    private var partyModeCheckbox: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showRegularView = true
                }
            }) {
                Image(systemName: "checkmark.square.fill")
                    .foregroundColor(neonTheme.accent)
                    .font(.system(size: 20))
            }
            
            Text("Party Mode")
                .font(.custom("Sanchez", size: 16))
                .fontWeight(.bold)
                .foregroundColor(neonTheme.text)
            
            Spacer()
        }
    }
    
    private var startPartyButton: some View {
        Button(action: handleStartParty) {
            Text("Start the Party 🎉")
                .font(.custom("Sanchez", size: 18))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(neonTheme.accent)
                .cornerRadius(12)
                .shadow(color: neonTheme.shadow, radius: 4, x: 0, y: 2)
        }
        .disabled(isCreating)
    }
    
    var body: some View {
        ZStack {
            // Neon background
            neonTheme.background.ignoresSafeArea()
            
            VStack {
                topNavigationBar
                
                Spacer()
                
                // Main popup content
                VStack(spacing: 24) {
                    // Title
                    Text("🎉 Create a Party Collage")
                        .font(.custom("Sanchez", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(neonTheme.text)
                    
                    themeSection
                    photosSection
                    partyDurationSection
                    partyModeCheckbox
                    startPartyButton
                }
                .padding(32)
                .background(neonTheme.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(neonTheme.border, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                        .padding(1)
                )
                .cornerRadius(20)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showRegularView) {
            CreateCollageView()
        }
    }
    
    private func handleStartParty() {
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                // Automatically fetch a random theme from the predefined themes
                let randomTheme = predefinedThemes.randomElement() ?? "Party Time 🎉"
                
                await appState.createNewCollageSession(
                    theme: randomTheme,
                    duration: selectedDuration,
                    isPartyMode: true
                )
                
                // Reload sessions
                await appState.loadCollageSessions()
                
                DispatchQueue.main.async {
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                }
            }
            DispatchQueue.main.async {
                isCreating = false
            }
        }
    }
}
