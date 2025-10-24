//
//  StickerLibraryView.swift
//  PATCH'D
//

import SwiftUI

// Sticker Library View
struct StickerLibraryView: View {
    @StateObject private var stickerManager = StickerManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory: String = "Food" // Default to Food category
    
    let onStickerSelected: (String) -> Void
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                categoryTabsView
                Divider()
                    .background(Color.gray.opacity(0.3))
                stickerGridView
            }
            .background(Color.black)
            .navigationTitle("Stickers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Refresh") {
                        Task {
                            await stickerManager.refreshStickers()
                        }
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .onAppear {
                handleOnAppear()
            }
            .onChange(of: stickerManager.categories) { oldValue, newValue in
                handleCategoriesChange(newValue)
            }
        }
    }
    
    // MARK: - Sub-Views
    
    private var categoryTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(stickerManager.categories) { category in
                    CategoryTab(
                        name: category.name,
                        isSelected: selectedCategory == category.name
                    ) {
                        selectedCategory = category.name
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 50)
        .background(Color.black)
    }
    
    @ViewBuilder
    private var stickerGridView: some View {
        if stickerManager.isLoading {
            loadingView
        } else if let selectedCat = selectedCategoryView {
            if selectedCat.stickers.isEmpty {
                emptyStateView
            } else {
                stickersScrollView(selectedCat)
            }
        } else {
            noCategoriesView
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Spacer()
        }
    }
    
    private var selectedCategoryView: StickerCategory? {
        stickerManager.categories.first(where: { $0.name == selectedCategory })
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 48))
                    .foregroundColor(.gray.opacity(0.6))
                Text("No stickers available")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("Check back later for new stickers")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.8))
            }
            Spacer()
        }
    }
    
    private var noCategoriesView: some View {
        VStack {
            Spacer()
            Text("No categories available")
                .foregroundColor(.gray)
            Spacer()
        }
    }
    
    private func stickersScrollView(_ category: StickerCategory) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(category.stickers) { sticker in
                    StickerThumbnail(sticker: sticker) {
                        onStickerSelected(sticker.url)
                        dismiss()
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleOnAppear() {
        print("StickerLibrary: onAppear - categories count: \(stickerManager.categories.count)")
        print("StickerLibrary: onAppear - selectedCategory: \(selectedCategory)")
        
        // Ensure Food category is selected if available, otherwise select first category
        if !stickerManager.categories.isEmpty {
            if stickerManager.categories.contains(where: { $0.name == "Food" }) {
                selectedCategory = "Food"
                print("StickerLibrary: Selected Food category")
            } else {
                selectedCategory = stickerManager.categories.first?.name ?? "Food"
                print("StickerLibrary: Selected first category: \(selectedCategory)")
            }
        } else {
            print("StickerLibrary: No categories available yet")
        }
    }
    
    private func handleCategoriesChange(_ newCategories: [StickerCategory]) {
        // When categories are loaded, ensure Food category is selected if available
        if !newCategories.isEmpty {
            if newCategories.contains(where: { $0.name == "Food" }) {
                selectedCategory = "Food"
            } else if !newCategories.contains(where: { $0.name == selectedCategory }) {
                // If current selection is not available, select first category
                selectedCategory = newCategories.first?.name ?? "Food"
            }
        }
    }
}

// MARK: - Category Tab
struct CategoryTab: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
        }
    }
}

// MARK: - Sticker Thumbnail
struct StickerThumbnail: View {
    let sticker: StickerItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            // Check if the URL is an emoji (fallback stickers)
            if sticker.url.count == 1 && sticker.url.unicodeScalars.first?.properties.isEmoji == true {
                // Display emoji directly
                Text(sticker.url)
                    .font(.system(size: 50))
                    .frame(width: 70, height: 70)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            } else {
                // Display image from URL
                AsyncImage(url: URL(string: sticker.url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                    case .failure(_):
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.gray)
                    case .empty:
                        ProgressView()
                            .frame(width: 70, height: 70)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
    }
}
