//
//  PATCH_DApp.swift
//  PATCH'D
//
//  Created by Ricardo Payares on 10/2/25.
//

import SwiftUI
import CoreText

@main
struct PATCH_DApp: App {
    init() {
        // Register Sanchez fonts
        registerFonts()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func registerFonts() {
        // Register Sanchez Regular
        if let fontURL = Bundle.main.url(forResource: "Sanchez-Regular", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
        
        // Register Sanchez Italic
        if let fontURL = Bundle.main.url(forResource: "Sanchez-Italic", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
}
