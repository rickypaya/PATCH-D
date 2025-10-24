//
//  OnboardingViews.swift
//  PATCH'D
//
//  Complete implementation with swipe gestures and animations
//

import SwiftUI

// MARK: - 🎯 SWIPE CONTAINER (Main Onboarding Flow)
/// Professional swipe-based onboarding with smooth transitions
struct OnboardingSwipeContainer: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    
    // Function to advance to next page
    func goToNextPage() {
        if currentPage < 3 {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPage += 1
            }
        }
    }
    
    // Function to go to home screen
    func goToHomeScreen() {
        if appState.currentUser != nil && appState.isAuthenticated {
            withAnimation(.easeInOut(duration: 0.5)) {
                appState.currentState = .homeScreen
            }
        } else {
            withAnimation(.easeInOut(duration: 0.5)) {
                appState.currentState = .onboardingSignUp
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background color F2E1C7
            Color(red: 0.949, green: 0.882, blue: 0.780).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Skip Button
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            appState.currentState = .homeScreen
                        }
                    }) {
                        Text("Skip")
                            .font(.custom("Sanchez", size: 16))
                            .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.top, 10)
                .padding(.trailing, 10)
                
                // Swipeable Content
                TabView(selection: $currentPage) {
                    Onboarding1Content(isActive: currentPage == 0, onNext: goToNextPage)
                        .tag(0)
                    
                    Onboarding2Content(isActive: currentPage == 1, onNext: goToNextPage)
                        .tag(1)
                    
                    Onboarding3Content(isActive: currentPage == 2, onNext: goToNextPage)
                        .tag(2)
                    
                    Onboarding4Content(isActive: currentPage == 3, onNext: goToNextPage, onStartCollaging: goToHomeScreen)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Page Indicator
                PageIndicator(numberOfPages: 4, currentPage: currentPage)
                    .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - 📷 Page 1: Create Collage (Stack Shuffle Animation)
struct Onboarding1Content: View {
    @EnvironmentObject var appState: AppState
    let isActive: Bool
    let onNext: () -> Void
    
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var iconRotation: Double = -180
    @State private var textOffset: CGFloat = 30
    @State private var textOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Animated Icon - Stack Shuffle
            ZStack {
                Image(systemName: "photo.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243).opacity(0.3))
                    .offset(x: -8, y: 8)
                    .rotationEffect(.degrees(iconRotation * 0.5))
                
                Image(systemName: "photo.fill")
                    .font(.system(size: 55))
                    .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243).opacity(0.5))
                    .offset(x: -4, y: 4)
                    .rotationEffect(.degrees(iconRotation * 0.7))
                
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    .rotationEffect(.degrees(iconRotation))
            }
            .padding(.bottom, 20)
            
            // Text
            VStack(spacing: 20) {
                Text("Create Your Collage")
                    .font(.custom("Sanchez", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .offset(y: textOffset)
                    .opacity(textOpacity)
                
                Text("Start by creating a new collage and inviting your friends to join")
                    .font(.custom("Sanchez", size: 16))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .offset(y: textOffset)
                    .opacity(textOpacity)
            }
            
            Spacer()
            
            // Next Button
            Button(action: onNext) {
                Text("Next")
                    .font(.custom("Sanchez", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(red: 0.220, green: 0.376, blue: 0.243))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                            .foregroundColor(Color(red: 0.078, green: 0.259, blue: 0.102))
                            .padding(2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .onChange(of: isActive) { oldValue, newValue in
            if newValue { triggerAnimations() } else { resetAnimations() }
        }
        .onAppear {
            if isActive { triggerAnimations() }
        }
    }
    
    private func triggerAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0).delay(0.1)) {
            iconScale = 1.0
            iconOpacity = 1.0
            iconRotation = 0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            textOffset = 0
            textOpacity = 1.0
        }
    }
    
    private func resetAnimations() {
        iconScale = 0.5
        iconOpacity = 0
        iconRotation = -180
        textOffset = 30
        textOpacity = 0
    }
}

// MARK: - 👥 Page 2: Invite Friends (People Coming Together)
struct Onboarding2Content: View {
    @EnvironmentObject var appState: AppState
    let isActive: Bool
    let onNext: () -> Void
    
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var person1Offset: CGFloat = -20
    @State private var person2Offset: CGFloat = 20
    @State private var textOffset: CGFloat = 30
    @State private var textOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Animated Icon - People Sliding Together
            ZStack {
                Image(systemName: "person.fill")
                    .font(.system(size: 35))
                    .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243).opacity(0.7))
                    .offset(x: person1Offset, y: 0)
                    .opacity(iconOpacity)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 35))
                    .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243).opacity(0.7))
                    .offset(x: person2Offset, y: 0)
                    .opacity(iconOpacity)
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity * 0.8)
            }
            .padding(.bottom, 20)
            
            // Text
            VStack(spacing: 20) {
                Text("Invite Friends")
                    .font(.custom("Sanchez", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .offset(y: textOffset)
                    .opacity(textOpacity)
                
                Text("Share your collage with friends using invite codes or direct links")
                    .font(.custom("Sanchez", size: 16))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .offset(y: textOffset)
                    .opacity(textOpacity)
            }
            
            Spacer()
            
            // Next Button
            Button(action: onNext) {
                Text("Next")
                    .font(.custom("Sanchez", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(red: 0.220, green: 0.376, blue: 0.243))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                            .foregroundColor(Color(red: 0.078, green: 0.259, blue: 0.102))
                            .padding(2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .onChange(of: isActive) { oldValue, newValue in
            if newValue { triggerAnimations() } else { resetAnimations() }
        }
        .onAppear {
            if isActive { triggerAnimations() }
        }
    }
    
    private func triggerAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0).delay(0.1)) {
            person1Offset = -15
            person2Offset = 15
            iconOpacity = 1.0
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0).delay(0.2)) {
            iconScale = 1.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            textOffset = 0
            textOpacity = 1.0
        }
    }
    
    private func resetAnimations() {
        iconScale = 0.5
        iconOpacity = 0
        person1Offset = -20
        person2Offset = 20
        textOffset = 30
        textOpacity = 0
    }
}

// MARK: - 📸 Page 3: Add Photos (Camera Flash)
struct Onboarding3Content: View {
    @EnvironmentObject var appState: AppState
    let isActive: Bool
    let onNext: () -> Void
    
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0
    @State private var flashOpacity: Double = 0
    @State private var flashScale: CGFloat = 0.5
    @State private var textOffset: CGFloat = 30
    @State private var textOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Animated Icon - Camera Flash
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(flashOpacity))
                    .frame(width: 100, height: 100)
                    .scaleEffect(flashScale)
                    .blur(radius: 20)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
            }
            .padding(.bottom, 20)
            
            // Text
            VStack(spacing: 20) {
                Text("Add Photos")
                    .font(.custom("Sanchez", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .offset(y: textOffset)
                    .opacity(textOpacity)
                
                Text("Upload photos, arrange them, and add stickers to create your perfect collage")
                    .font(.custom("Sanchez", size: 16))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .offset(y: textOffset)
                    .opacity(textOpacity)
            }
            
            Spacer()
            
            // Next Button
            Button(action: onNext) {
                Text("Next")
                    .font(.custom("Sanchez", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(red: 0.220, green: 0.376, blue: 0.243))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                            .foregroundColor(Color(red: 0.078, green: 0.259, blue: 0.102))
                            .padding(2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .onChange(of: isActive) { oldValue, newValue in
            if newValue { triggerAnimations() } else { resetAnimations() }
        }
        .onAppear {
            if isActive { triggerAnimations() }
        }
    }
    
    private func triggerAnimations() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0).delay(0.1)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.25)) {
            flashOpacity = 0.8
            flashScale = 2.0
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.4)) {
            flashOpacity = 0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            textOffset = 0
            textOpacity = 1.0
        }
    }
    
    private func resetAnimations() {
        iconScale = 0.8
        iconOpacity = 0
        flashOpacity = 0
        flashScale = 0.5
        textOffset = 30
        textOpacity = 0
    }
}

// MARK: - ❤️ Page 4: Share & Enjoy (Heartbeat + Particles)
struct Onboarding4Content: View {
    @EnvironmentObject var appState: AppState
    let isActive: Bool
    let onNext: () -> Void
    let onStartCollaging: () -> Void
    
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var heartBeat: CGFloat = 1.0
    @State private var particleOpacity: Double = 0
    @State private var particleOffset: CGFloat = 0
    @State private var textOffset: CGFloat = 30
    @State private var textOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Animated Icon - Heartbeat + Particles
            ZStack {
                ForEach(0..<6) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243).opacity(particleOpacity))
                        .offset(
                            x: cos(Double(index) * .pi / 3) * (30 + particleOffset),
                            y: sin(Double(index) * .pi / 3) * (30 + particleOffset)
                        )
                }
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                    .scaleEffect(iconScale * heartBeat)
                    .opacity(iconOpacity)
            }
            .padding(.bottom, 20)
            
            // Text
            VStack(spacing: 20) {
                Text("Share & Enjoy")
                    .font(.custom("Sanchez", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .offset(y: textOffset)
                    .opacity(textOpacity)
                
                Text("Save your collage, share it with friends, and create lasting memories together")
                    .font(.custom("Sanchez", size: 16))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .offset(y: textOffset)
                    .opacity(textOpacity)
            }
            
            Spacer()
            
            // Start Collaging Button
            Button(action: onStartCollaging) {
                Text("Start Collaging!")
                    .font(.custom("Sanchez", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(red: 0.220, green: 0.376, blue: 0.243))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                            .foregroundColor(Color(red: 0.078, green: 0.259, blue: 0.102))
                            .padding(2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .onChange(of: isActive) { oldValue, newValue in
            if newValue { triggerAnimations() } else { resetAnimations() }
        }
        .onAppear {
            if isActive { triggerAnimations() }
        }
    }
    
    private func triggerAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0).delay(0.1)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.3)) {
            heartBeat = 1.1
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            particleOpacity = 1.0
            particleOffset = 10
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            particleOpacity = 0
            particleOffset = 30
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            textOffset = 0
            textOpacity = 1.0
        }
    }
    
    private func resetAnimations() {
        iconScale = 0.5
        iconOpacity = 0
        heartBeat = 1.0
        particleOpacity = 0
        particleOffset = 0
        textOffset = 30
        textOpacity = 0
    }
}

// MARK: - 🔄 Legacy Views (Redirect to Swipe Container)
struct Onboarding1View: View {
    var body: some View {
        OnboardingSwipeContainer()
    }
}

struct Onboarding2View: View {
    var body: some View {
        OnboardingSwipeContainer()
    }
}

struct Onboarding3View: View {
    var body: some View {
        OnboardingSwipeContainer()
    }
}

struct Onboarding4View: View {
    var body: some View {
        OnboardingSwipeContainer()
    }
}

// MARK: - 🎨 Title Screen (UNCHANGED from your original)
struct OnboardingTitleView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color(red: 0.949, green: 0.886, blue: 0.784).ignoresSafeArea()
            
            VStack(spacing: 0) {
                CheckeredBorderView()
                
                ZStack {
                    Color(red: 0.949, green: 0.886, blue: 0.784)
                    
                    VStack(spacing: 60) {
                        Spacer()

                        Image("Patch'd_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 80)

                        Spacer()

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                appState.currentState = .onboardingWelcome
                            }
                        }) {
                            Text("Get Started")
                                .font(.custom("Sanchez", size: 18))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color(red: 0.220, green: 0.376, blue: 0.243))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                        .foregroundColor(Color(red: 0.078, green: 0.259, blue: 0.102))
                                        .padding(2)
                                )
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 30)
                    }
                }
                
                CheckeredBorderView()
            }
        }
    }
}

// MARK: - Checkered Border (UNCHANGED)
struct CheckeredBorderView: View {
    private let squareSize: CGFloat = 20
    private let rows = 2
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let columns = Int(ceil(screenWidth / squareSize))
            
            VStack(spacing: 0) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<columns, id: \.self) { column in
                            Rectangle()
                                .fill(checkeredColor(row: row, column: column))
                                .frame(width: squareSize, height: squareSize)
                        }
                    }
                }
            }
        }
        .frame(height: CGFloat(rows) * squareSize)
    }
    
    private func checkeredColor(row: Int, column: Int) -> Color {
        let isEven = (row + column) % 2 == 0
        return isEven ?
            Color(red: 0.659, green: 0.761, blue: 0.682) :
            Color(red: 0.961, green: 0.937, blue: 0.910)
    }
}

// MARK: - Welcome Screen (UNCHANGED)
struct OnboardingWelcome_SignUporLogInView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            Color(red: 0.949, green: 0.882, blue: 0.780).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                Image("Patch'd_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 60)
                
                Text("Welcome to PATCH'D")
                    .font(.custom("Sanchez", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text("Create photo collages with friends")
                    .font(.custom("Sanchez", size: 18))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            appState.currentState = .onboardingSignUp
                        }
                    }) {
                        Text("Sign up")
                            .font(.custom("Sanchez", size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(red: 0.220, green: 0.376, blue: 0.243))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                    .foregroundColor(Color(red: 0.078, green: 0.259, blue: 0.102))
                                    .padding(2)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            appState.currentState = .onboardingSignIn
                        }
                    }) {
                        Text("Log in")
                            .font(.custom("Sanchez", size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(red: 0.204, green: 0.275, blue: 0.494))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                    .foregroundColor(Color(red: 0.075, green: 0.145, blue: 0.365))
                                    .padding(2)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - 📝 Sign Up Screen (Keep ALL your auth logic)
struct OnboardingSignUpView: View {
    @EnvironmentObject var appState: AppState
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showEmailError: Bool = false
    @State private var showPasswordError: Bool = false
    @State private var showGeneralError: Bool = false
    @State private var generalErrorMessage: String = ""
    @State private var isLoading: Bool = false
    
    private var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private var isPasswordValid: Bool {
        return password.count >= 6
    }
    
    private var isFormValid: Bool {
        return !name.isEmpty && isEmailValid && isPasswordValid && !isLoading
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.949, green: 0.886, blue: 0.784).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 60)
                    
                    Image("Patch'd_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                    
                    Spacer(minLength: 20)
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.custom("Sanchez", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                            
                            TextField("Enter your profile name", text: $name)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("E-mail")
                                .font(.custom("Sanchez", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                            
                            TextField("Enter your e-mail address", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .onChange(of: email) {
                                    showEmailError = !email.isEmpty && !isEmailValid
                                    showGeneralError = false
                                }
                            
                            if showEmailError {
                                Text("Please enter a valid email address.")
                                    .font(.custom("Sanchez", size: 12))
                                    .foregroundColor(Color(red: 0.765, green: 0.216, blue: 0.149))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.custom("Sanchez", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                            
                            SecureField("Enter at least 6 characters", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                                .onChange(of: password) {
                                    showPasswordError = !password.isEmpty && !isPasswordValid
                                    showGeneralError = false
                                }
                            
                            if showPasswordError {
                                Text("Password must be at least 6 characters.")
                                    .font(.custom("Sanchez", size: 12))
                                    .foregroundColor(Color(red: 0.765, green: 0.216, blue: 0.149))
                            }
                        }
                    }
                    
                    Spacer(minLength: 5)
                    
                    if showGeneralError {
                        Text(generalErrorMessage)
                            .font(.custom("Sanchez", size: 14))
                            .foregroundColor(Color(red: 0.765, green: 0.216, blue: 0.149))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 0)
                    
                    Button(action: {
                        Task {
                            await handleSignUp()
                        }
                    }) {
                        ZStack {
                            Image("blockbutton-blank-green")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                            
                            VStack {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    Text("Create my account")
                                        .font(.custom("Sanchez", size: 18))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .padding(.top, 8)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                    }
                    .disabled(!isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            appState.currentState = .onboardingSignIn
                        }
                    }) {
                        Text("Already have an account? Log in")
                            .font(.custom("Sanchez", size: 14))
                            .italic()
                            .foregroundColor(.black)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private func handleSignUp() async {
        guard isFormValid else { return }
        
        isLoading = true
        showGeneralError = false
        
        do {
            try await appState.signUpWithEmail(email: email, password: password, username: name)
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    appState.currentState = .registrationSuccess
                }
            }
        } catch {
            await MainActor.run {
                let errorMessage = error.localizedDescription.lowercased()
                if errorMessage.contains("already") || errorMessage.contains("exists") || errorMessage.contains("registered") {
                    generalErrorMessage = "This email is already registered. Please log in instead."
                } else if errorMessage.contains("network") || errorMessage.contains("connection") {
                    generalErrorMessage = "Network error. Please check your internet connection and try again."
                } else if errorMessage.contains("invalid") {
                    generalErrorMessage = "Invalid email or password format. Please check and try again."
                } else {
                    generalErrorMessage = "Unable to create account. Please try again later."
                }
                
                showGeneralError = true
                isLoading = false
            }
        }
    }
}

// MARK: - 🔐 Sign In Screen (Keep ALL your auth logic)
struct OnboardingSignInView: View {
    @EnvironmentObject var appState: AppState
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    
    private var isFormValid: Bool {
        return !email.isEmpty && !password.isEmpty && !isLoading
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.949, green: 0.886, blue: 0.784).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 80)
                    
                    Image("Patch'd_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                    
                    Spacer(minLength: 40)
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("E-mail")
                                .font(.custom("Sanchez", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                            
                            TextField("Enter your e-mail address", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .onChange(of: email) {
                                    showError = false
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.custom("Sanchez", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                                .onChange(of: password) {
                                    showError = false
                                }
                        }
                    }
                    
                    Spacer(minLength: 10)
                    
                    if showError {
                        Text(errorMessage)
                            .font(.custom("Sanchez", size: 14))
                            .foregroundColor(Color(red: 0.765, green: 0.216, blue: 0.149))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 0)
                    
                    Button(action: {
                        Task {
                            await handleSignIn()
                        }
                    }) {
                        ZStack {
                            Image("blockbutton-blank-green")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                            
                            VStack {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    Text("Log in")
                                        .font(.custom("Sanchez", size: 18))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .padding(.top, 8)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                    }
                    .disabled(!isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            appState.currentState = .onboardingSignUp
                        }
                    }) {
                        Text("Don't have an account? Sign up")
                            .font(.custom("Sanchez", size: 14))
                            .italic()
                            .foregroundColor(.black)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private func handleSignIn() async {
        guard isFormValid else { return }
        
        isLoading = true
        showError = false
        
        do {
            try await appState.signInWithEmail(email: email, password: password)
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    appState.currentState = .homeScreen
                }
            }
        } catch {
            await MainActor.run {
                let errorText = error.localizedDescription.lowercased()
                if errorText.contains("invalid") || errorText.contains("credentials") || errorText.contains("wrong") {
                    errorMessage = "Invalid email or password. Please try again."
                } else if errorText.contains("network") || errorText.contains("connection") {
                    errorMessage = "Network error. Please check your internet connection."
                } else if errorText.contains("not found") {
                    errorMessage = "No account found with this email. Please sign up first."
                } else {
                    errorMessage = "Unable to sign in. Please try again later."
                }
                
                showError = true
                isLoading = false
            }
        }
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .offset(y: -4)
            .background(
                Image("SignUp_field")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 56)
            )
            .cornerRadius(8)
            .foregroundColor(Color.black)
            .font(.custom("Sanchez", size: 16))
    }
}

// MARK: - ✅ Registration Success Screen
struct RegistrationSuccessView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            Color(red: 0.949, green: 0.882, blue: 0.780).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                
                VStack(spacing: 16) {
                    Text("Account Created!")
                        .font(.custom("Sanchez", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("Welcome to PATCH'D!\nSign in with your email and password next time to keep patching.")
                        .font(.custom("Sanchez", size: 16))
                        .foregroundColor(.black.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        appState.currentState = .onboarding1  // Goes to swipe container!
                    }
                }) {
                    Text("Get Started")
                        .font(.custom("Sanchez", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 0.220, green: 0.376, blue: 0.243))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                .foregroundColor(Color(red: 0.078, green: 0.259, blue: 0.102))
                                .padding(2)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Preview
#Preview("Complete Onboarding Flow") {
    ContentView()
        .environmentObject(AppState.shared)
}

#Preview("Title Screen") {
    OnboardingTitleView()
        .environmentObject(AppState.shared)
}

#Preview("Welcome Screen") {
    OnboardingWelcome_SignUporLogInView()
        .environmentObject(AppState.shared)
}

#Preview("Sign Up Screen") {
    OnboardingSignUpView()
        .environmentObject(AppState.shared)
}

#Preview("Log In Screen") {
    OnboardingSignInView()
        .environmentObject(AppState.shared)
}

#Preview("Registration Success") {
    RegistrationSuccessView()
        .environmentObject(AppState.shared)
}

#Preview("Onboarding 1") {
    Onboarding1View()
        .environmentObject(AppState.shared)
}

#Preview("Onboarding 2") {
    Onboarding2View()
        .environmentObject(AppState.shared)
}

#Preview("Onboarding 3") {
    Onboarding3View()
        .environmentObject(AppState.shared)
}

#Preview("Onboarding 4") {
    Onboarding4View()
        .environmentObject(AppState.shared)
}

#Preview("Swipe Container") {
    OnboardingSwipeContainer()
        .environmentObject(AppState.shared)
}
