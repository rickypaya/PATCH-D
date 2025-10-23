//
//  PageIndicator.swift
//  PATCH'D
//
//  Professional page indicator component for onboarding flow
//  Features smooth animations and polished design
//

import SwiftUI

struct PageIndicator: View {
    //  Properties
    let numberOfPages: Int
    let currentPage: Int
    
    //  Design System Colors
    // Warm coral-orange that matches your brand - professionally calibrated
    private let activeColor = Color(red: 0.92, green: 0.38, blue: 0.22) // #EB6138
    private let inactiveColor = Color.black.opacity(0.25)
    
    //  Design System Spacing & Sizing
    private let activeDotSize: CGFloat = 12
    private let activeRingSize: CGFloat = 20
    private let inactiveDotSize: CGFloat = 8
    private let dotSpacing: CGFloat = 10
    private let bottomPadding: CGFloat = 40
    private let ringLineWidth: CGFloat = 1.8
    
    //  Animation Configuration
    private let animationDuration: Double = 0.35
    private let animationSpring = Animation.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0)
    
    var body: some View {
        HStack(spacing: dotSpacing) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                ZStack {
                    if index == currentPage {
                        // ACTIVE INDICATOR - Filled circle with breathing ring
                        Circle()
                            .fill(activeColor)
                            .frame(width: activeDotSize, height: activeDotSize)
                            .overlay(
                                Circle()
                                    .stroke(activeColor, lineWidth: ringLineWidth)
                                    .frame(width: activeRingSize, height: activeRingSize)
                                    .opacity(0.4) // Subtle ring opacity for depth
                            )
                            .shadow(color: activeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        // INACTIVE INDICATOR - Small subtle dot
                        Circle()
                            .fill(inactiveColor)
                            .frame(width: inactiveDotSize, height: inactiveDotSize)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: activeRingSize, height: activeRingSize) // Consistent hit area
                .animation(animationSpring, value: currentPage)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: activeRingSize + 20) // Ensure consistent vertical space
        .padding(.bottom, bottomPadding)
    }
}

//  Alternate Style (Elegant Variant)
/// Use this if you want a more minimalist look
struct PageIndicatorMinimal: View {
    let numberOfPages: Int
    let currentPage: Int
    
    private let activeColor = Color(red: 0.92, green: 0.38, blue: 0.22)
    private let inactiveColor = Color.black.opacity(0.2)
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? activeColor : inactiveColor)
                    .frame(
                        width: index == currentPage ? 24 : 8,
                        height: 8
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 40)
    }
}

//  Animated Variant (Extra Polish)
/// Premium version with scale pulse effect
struct PageIndicatorPremium: View {
    let numberOfPages: Int
    let currentPage: Int
    
    @State private var pulseScale: CGFloat = 1.0
    
    private let activeColor = Color(red: 0.92, green: 0.38, blue: 0.22)
    private let inactiveColor = Color.black.opacity(0.25)
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                ZStack {
                    if index == currentPage {
                        // Active with subtle pulse
                        Circle()
                            .fill(activeColor)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(activeColor, lineWidth: 1.8)
                                    .frame(width: 20, height: 20)
                                    .scaleEffect(pulseScale)
                                    .opacity(0.6)
                            )
                            .shadow(color: activeColor.opacity(0.4), radius: 6, x: 0, y: 3)
                            .onAppear {
                                withAnimation(
                                    .easeInOut(duration: 1.2)
                                    .repeatForever(autoreverses: true)
                                ) {
                                    pulseScale = 1.15
                                }
                            }
                    } else {
                        Circle()
                            .fill(inactiveColor)
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(width: 20, height: 20)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentPage)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 40)
    }
}

//  Accessibility Enhanced Version
/// WCAG compliant with improved contrast and touch targets
struct PageIndicatorAccessible: View {
    let numberOfPages: Int
    let currentPage: Int
    
    private let activeColor = Color(red: 0.92, green: 0.38, blue: 0.22)
    private let inactiveColor = Color.black.opacity(0.35) // Higher contrast
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                ZStack {
                    if index == currentPage {
                        Circle()
                            .fill(activeColor)
                            .frame(width: 14, height: 14) // Slightly larger for accessibility
                            .overlay(
                                Circle()
                                    .stroke(activeColor, lineWidth: 2)
                                    .frame(width: 22, height: 22)
                                    .opacity(0.5)
                            )
                            .shadow(color: activeColor.opacity(0.35), radius: 4, x: 0, y: 2)
                    } else {
                        Circle()
                            .fill(inactiveColor)
                            .frame(width: 10, height: 10) // Larger inactive for better visibility
                    }
                }
                .frame(width: 44, height: 44) // iOS minimum touch target
                .contentShape(Rectangle()) // Ensure full frame is tappable
                .accessibilityLabel("Page \(index + 1) of \(numberOfPages)")
                .accessibilityAddTraits(index == currentPage ? [.isSelected] : [])
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentPage)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 40)
        .accessibilityElement(children: .contain)
    }
}

//  Preview Canvas
#Preview("Standard Style") {
    VStack(spacing: 60) {
        VStack {
            Text("Page 1 of 4")
                .font(.caption)
                .foregroundColor(.gray)
            PageIndicator(numberOfPages: 4, currentPage: 0)
        }
        
        VStack {
            Text("Page 2 of 4")
                .font(.caption)
                .foregroundColor(.gray)
            PageIndicator(numberOfPages: 4, currentPage: 1)
        }
        
        VStack {
            Text("Page 3 of 4")
                .font(.caption)
                .foregroundColor(.gray)
            PageIndicator(numberOfPages: 4, currentPage: 2)
        }
        
        VStack {
            Text("Page 4 of 4")
                .font(.caption)
                .foregroundColor(.gray)
            PageIndicator(numberOfPages: 4, currentPage: 3)
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(red: 1.0, green: 0.98, blue: 0.9))
}

#Preview("All Variants") {
    ScrollView {
        VStack(spacing: 50) {
            VStack(spacing: 10) {
                Text("Standard (Recommended)")
                    .font(.headline)
                PageIndicator(numberOfPages: 4, currentPage: 1)
            }
            
            Divider()
            
            VStack(spacing: 10) {
                Text("Minimal")
                    .font(.headline)
                PageIndicatorMinimal(numberOfPages: 4, currentPage: 1)
            }
            
            Divider()
            
            VStack(spacing: 10) {
                Text("Premium (Pulsing)")
                    .font(.headline)
                PageIndicatorPremium(numberOfPages: 4, currentPage: 1)
            }
            
            Divider()
            
            VStack(spacing: 10) {
                Text("Accessible")
                    .font(.headline)
                PageIndicatorAccessible(numberOfPages: 4, currentPage: 1)
            }
        }
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(red: 1.0, green: 0.98, blue: 0.9))
}
