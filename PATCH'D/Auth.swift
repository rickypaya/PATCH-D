//
//  Auth.swift
//  PATCH'D
//
//  Created by Ricardo Payares on 10/15/25.
//
import SwiftUI

//MARK: - Login View
struct LogInView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to PATCH'D")
                .font(.largeTitle.bold())
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Sign In") {
                Task { try await appState.signInWithEmail(email: email, password: password) }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

//MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to PATCH'D")
                .font(.largeTitle.bold())
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Sign Up") {
                Task {
                    print("Called sign up task")
                    try await appState.signUpWithEmail(email: email, password: password, username: username) }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Log In") {
                Task {
                    appState.currentState = .logIn
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
