//
//  OnboardingViews.swift
//  PATCH'D
//
//  Created by AI Assistant
//

import SwiftUI

// MARK: - Title Screen
struct OnboardingTitleView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Main background color F2E2C8
            Color(red: 0.949, green: 0.886, blue: 0.784).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top checkered border
                CheckeredBorderView()
                
                // Main content area
                ZStack {
                    // Background color F2E2C8
                    Color(red: 0.949, green: 0.886, blue: 0.784)
                    
                    VStack(spacing: 60) {
                        Spacer()

                        // Logo from assets - centered and proportional
                        Image("Patch'd_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 80) // Increased size to match image proportions

                        Spacer()

                        // Get Started button with dotted patched border
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
                                .background(Color(red: 0.220, green: 0.376, blue: 0.243)) // 38603E
                                .cornerRadius(12)
                                .overlay(
                                    // Dotted patched border - 1-2px inside
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                        .foregroundColor(Color(red: 0.078, green: 0.259, blue: 0.102)) // 14421A
                                        .padding(2)
                                )
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 30)
                    }
                }
                
                // Bottom checkered border
                CheckeredBorderView()
            }
        }
    }
}

// MARK: - Checkered Border Component
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
            Color(red: 0.659, green: 0.761, blue: 0.682) : // A8C2AE
            Color(red: 0.961, green: 0.937, blue: 0.910)   // F5EFE8
    }
}

// MARK: - Welcome Screen
struct OnboardingWelcome_SignUporLogInView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Background color F2E1C7
            Color(red: 0.949, green: 0.882, blue: 0.780).ignoresSafeArea()
            
            // Main content
            VStack(spacing: 40) {
                Spacer()
                
                // Logo from assets
                Image("Patch'd_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 60)
                
                // Welcome text
                Text("Welcome to PATCH'D")
                    .font(.custom("Sanchez", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text("Create photo collages with friends")
                    .font(.custom("Sanchez", size: 18))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // Two buttons stacked vertically
                VStack(spacing: 16) {
                    // Sign up button (green)
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
                            .background(Color(red: 0.220, green: 0.376, blue: 0.243)) // Green
                            .cornerRadius(12)
                            .overlay(
                                // Dotted patched border - 2px inside
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                    .foregroundColor(Color(red: 0.078, green: 0.259, blue: 0.102)) // 14421A
                                    .padding(2)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    
                    // Log in button (navy)
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
                            .background(Color(red: 0.204, green: 0.275, blue: 0.494)) // 34467E
                            .cornerRadius(12)
                            .overlay(
                                // Dotted patched border - 2px inside
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                    .foregroundColor(Color(red: 0.075, green: 0.145, blue: 0.365)) // 13255D
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

// MARK: - Sign Up Screen
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
            // Background color F2E1C7
            Color(red: 0.949, green: 0.882, blue: 0.780).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 60)
                    
                    // Logo from assets
                    Image("Patch'd_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                    
                    Spacer(minLength: 20)
                    
                    VStack(spacing: 20) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.custom("Sanchez", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                            
                            TextField("Enter your profile name", text: $name)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("E-mail")
                                .font(.custom("Sanchez", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                            
                            TextField("Enter your e-mail address", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .onChange(of: email) { _ in
                                    showEmailError = !email.isEmpty && !isEmailValid
                                    showGeneralError = false // Clear general error when user types
                                }
                            
                            if showEmailError {
                                Text("Please enter a valid email address.")
                                    .font(.custom("Sanchez", size: 12))
                                    .foregroundColor(Color(red: 0.765, green: 0.216, blue: 0.149)) // C33726
                            }
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.custom("Sanchez", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                            
                            SecureField("Enter at least 6 characters", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                                .onChange(of: password) { _ in
                                    showPasswordError = !password.isEmpty && !isPasswordValid
                                    showGeneralError = false // Clear general error when user types
                                }
                            
                            if showPasswordError {
                                Text("Password must be at least 6 characters.")
                                    .font(.custom("Sanchez", size: 12))
                                    .foregroundColor(Color(red: 0.765, green: 0.216, blue: 0.149)) // C33726
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                    
                    // General validation message
                    if showGeneralError {
                        Text(generalErrorMessage)
                            .font(.custom("Sanchez", size: 14))
                            .foregroundColor(Color(red: 0.765, green: 0.216, blue: 0.149)) // C33726
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 10)
                    
                    // Create account button
                    Button(action: {
                        Task {
                            await handleSignUp()
                        }
                    }) {
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
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 0.220, green: 0.376, blue: 0.243))
                        .cornerRadius(12)
                        .overlay(
                            // Dotted patched border - 2px inside
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                .foregroundColor(Color(red: 0.078, green: 0.259, blue: 0.102)) // 14421A
                                .padding(2)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .disabled(!isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    
                    // Login link
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
            print("DEBUG: Sign up successful")
            
            // User created successfully, navigate to registration success page
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    appState.currentState = .registrationSuccess
                }
            }
        } catch {
            // Handle specific Supabase errors
            await MainActor.run {
                // Check if the error message indicates user already exists
                let errorMessage = error.localizedDescription.lowercased()
                if errorMessage.contains("already registered") || 
                   errorMessage.contains("user already exists") || 
                   errorMessage.contains("email already") ||
                   errorMessage.contains("already been registered") {
                    generalErrorMessage = "This email is already registered. Log in instead?"
                } else if let error = error as? AuthError {
                    switch error {
                    case .userAlreadyRegistered:
                        generalErrorMessage = "This email is already registered. Log in instead?"
                    default:
                        generalErrorMessage = "Sign up failed. Please try again."
                    }
                } else {
                    generalErrorMessage = "Sign up failed. Please try again."
                }
                showGeneralError = true
            }
        }
        
        isLoading = false
    }
}

// MARK: - Log In Screen
struct OnboardingSignInView: View {
    @EnvironmentObject var appState: AppState
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
        return isEmailValid && isPasswordValid && !isLoading
    }
    
    var body: some View {
        ZStack {
            // Background color F2E1C7
            Color(red: 0.949, green: 0.882, blue: 0.780).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 60)
                    
                    // Logo from assets
                    Image("Patch'd_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                    
                    Spacer(minLength: 20)
                    
                    VStack(spacing: 20) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("E-mail")
                                .font(.custom("Sanchez", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                            
                            TextField("Enter your e-mail address", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .onChange(of: email) { _ in
                                    showEmailError = !email.isEmpty && !isEmailValid
                                    showGeneralError = false // Clear general error when user types
                                }
                            
                            if showEmailError {
                                Text("Please enter a valid email address.")
                                    .font(.custom("Sanchez", size: 12))
                                    .foregroundColor(Color(red: 0.765, green: 0.216, blue: 0.149)) // C33726
                            }
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.custom("Sanchez", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                                .onChange(of: password) { _ in
                                    showPasswordError = !password.isEmpty && !isPasswordValid
                                    showGeneralError = false // Clear general error when user types
                                }
                            
                            if showPasswordError {
                                Text("Password must be at least 6 characters.")
                                    .font(.custom("Sanchez", size: 12))
                                    .foregroundColor(Color(red: 0.765, green: 0.216, blue: 0.149)) // C33726
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                    
                    // General validation message
                    if showGeneralError {
                        Text(generalErrorMessage)
                            .font(.custom("Sanchez", size: 14))
                            .foregroundColor(Color(red: 0.765, green: 0.216, blue: 0.149)) // C33726
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 10)
                    
                    // Log in button
                    Button(action: {
                        Task {
                            await handleSignIn()
                        }
                    }) {
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
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 0.220, green: 0.376, blue: 0.243))
                        .cornerRadius(12)
                        .overlay(
                            // Dotted patched border - 2px inside
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                .foregroundColor(Color(red: 0.078, green: 0.259, blue: 0.102)) // 14421A
                                .padding(2)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .disabled(!isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    
                    // Sign up link
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
        guard isFormValid else { 
            print("DEBUG: Form validation failed - email: \(email), password length: \(password.count)")
            return 
        }
        
        print("DEBUG: Starting sign in process for email: \(email)")
        isLoading = true
        showGeneralError = false
        
        do {
            try await appState.signInWithEmail(email: email, password: password)
            print("DEBUG: Sign in successful")
            
            // Successful login, navigate to home screen
            await MainActor.run {
                print("DEBUG: Navigating to home screen")
                withAnimation(.easeInOut(duration: 0.5)) {
                    appState.currentState = .homeScreen
                }
            }
        } catch {
            print("DEBUG: Sign in failed with error: \(error)")
            print("DEBUG: Error localized description: \(error.localizedDescription)")
            
            // Handle specific Supabase errors
            await MainActor.run {
                if let error = error as? AuthError {
                    switch error {
                    case .invalidCredentials:
                        generalErrorMessage = "Incorrect password. Try again?"
                    case .userNotFound:
                        generalErrorMessage = "No account found with this email. Want to sign up?"
                    default:
                        generalErrorMessage = "Login failed. Please try again."
                    }
                } else {
                    // Check error message for specific cases
                    let errorMessage = error.localizedDescription.lowercased()
                    if errorMessage.contains("invalid login credentials") || errorMessage.contains("invalid password") {
                        generalErrorMessage = "Incorrect password. Try again?"
                    } else if errorMessage.contains("user not found") || errorMessage.contains("email not confirmed") {
                        generalErrorMessage = "No account found with this email. Want to sign up?"
                    } else {
                        generalErrorMessage = "Login failed. Please try again."
                    }
                }
                showGeneralError = true
            }
        }
        
        isLoading = false
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 0.949, green: 0.882, blue: 0.780))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundColor(Color(red: 0.8, green: 0.7, blue: 0.6))
            )
            .font(.custom("Sanchez", size: 16))
    }
}

// MARK: - Registration Success Screen
struct RegistrationSuccessView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Background color F2E1C7
            Color(red: 0.949, green: 0.882, blue: 0.780).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                
                // Success message
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
                
                // Get Started button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        appState.currentState = .onboarding1
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
                            // Dotted patched border - 2px inside
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                .foregroundColor(Color(red: 0.078, green: 0.259, blue: 0.102)) // 14421A
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

// MARK: - Onboarding Step 1
struct Onboarding1View: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Background color F2E1C7
            Color(red: 0.949, green: 0.882, blue: 0.780).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Step 1 content
                VStack(spacing: 20) {
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                    
                    Text("Create Your Collage")
                        .font(.custom("Sanchez", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("Start by creating a new collage and inviting your friends to join")
                        .font(.custom("Sanchez", size: 16))
                        .foregroundColor(.black.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Continue button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        appState.currentState = .onboarding2
                    }
                }) {
                    Text("Next")
                        .font(.custom("Sanchez", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 0.220, green: 0.376, blue: 0.243))
                        .cornerRadius(12)
                        .overlay(
                            // Dotted patched border - 2px inside
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                .foregroundColor(Color(red: 0.078, green: 0.259, blue: 0.102)) // 14421A
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

// MARK: - Onboarding Step 2
struct Onboarding2View: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Background color F2E1C7
            Color(red: 0.949, green: 0.882, blue: 0.780).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Step 2 content
                VStack(spacing: 20) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                    
                    Text("Invite Friends")
                        .font(.custom("Sanchez", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("Share your collage with friends using invite codes or direct links")
                        .font(.custom("Sanchez", size: 16))
                        .foregroundColor(.black.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Continue button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        appState.currentState = .onboarding3
                    }
                }) {
                    Text("Next")
                        .font(.custom("Sanchez", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 0.220, green: 0.376, blue: 0.243))
                        .cornerRadius(12)
                        .overlay(
                            // Dotted patched border - 2px inside
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                .foregroundColor(Color(red: 0.078, green: 0.259, blue: 0.102)) // 14421A
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

// MARK: - Onboarding Step 3
struct Onboarding3View: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Background color F2E1C7
            Color(red: 0.949, green: 0.882, blue: 0.780).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Step 3 content
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                    
                    Text("Add Photos")
                        .font(.custom("Sanchez", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("Upload photos, arrange them, and add stickers to create your perfect collage")
                        .font(.custom("Sanchez", size: 16))
                        .foregroundColor(.black.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Continue button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        appState.currentState = .onboarding4
                    }
                }) {
                    Text("Next")
                        .font(.custom("Sanchez", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 0.220, green: 0.376, blue: 0.243))
                        .cornerRadius(12)
                        .overlay(
                            // Dotted patched border - 2px inside
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                .foregroundColor(Color(red: 0.078, green: 0.259, blue: 0.102)) // 14421A
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

// MARK: - Onboarding Step 4
struct Onboarding4View: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Background color F2E1C7
            Color(red: 0.949, green: 0.882, blue: 0.780).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Step 4 content
                VStack(spacing: 20) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.220, green: 0.376, blue: 0.243))
                    
                    Text("Share & Enjoy")
                        .font(.custom("Sanchez", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("Save your collage, share it with friends, and create lasting memories together")
                        .font(.custom("Sanchez", size: 16))
                        .foregroundColor(.black.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Start Collaging button
                Button(action: {
                    print("DEBUG: Start Collaging button tapped")
                    print("DEBUG: Current user: \(appState.currentUser?.email ?? "nil")")
                    print("DEBUG: Is authenticated: \(appState.isAuthenticated)")
                    
                    // Check if user is authenticated before proceeding to home screen
                    if appState.currentUser != nil && appState.isAuthenticated {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            appState.currentState = .homeScreen
                        }
                    } else {
                        print("DEBUG: User not authenticated, redirecting to sign up")
                        withAnimation(.easeInOut(duration: 0.5)) {
                            appState.currentState = .onboardingSignUp
                        }
                    }
                }) {
                    Text("Start Collaging!")
                        .font(.custom("Sanchez", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 0.220, green: 0.376, blue: 0.243))
                        .cornerRadius(12)
                        .overlay(
                            // Dotted patched border - 2px inside
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                .foregroundColor(Color(red: 0.078, green: 0.259, blue: 0.102)) // 14421A
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

// MARK: - Complete Onboarding Flow Preview
struct CompleteOnboardingFlowPreview: View {
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        ZStack {
            switch appState.currentState {
            case .onboardingTitle:
                OnboardingTitleView()
            case .onboardingWelcome:
                OnboardingWelcome_SignUporLogInView()
            case .onboardingSignUp:
                OnboardingSignUpView()
            case .onboardingSignIn:
                OnboardingSignInView()
            case .registrationSuccess:
                RegistrationSuccessView()
            case .onboarding1:
                Onboarding1View()
            case .onboarding2:
                Onboarding2View()
            case .onboarding3:
                Onboarding3View()
            case .onboarding4:
                Onboarding4View()
            case .homeScreen:
                HomeScreenView()
            case .homeCollageCarousel:
                HomeScreenView()
            default:
                OnboardingTitleView()
            }
        }
        .environmentObject(appState)
    }
}

#Preview("Complete Onboarding Flow") {
    CompleteOnboardingFlowPreview()
        .environmentObject(AppState.shared)
}
