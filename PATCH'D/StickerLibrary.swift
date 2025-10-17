//
//  StickerLibraryView.swift
//  PATCH'D
//

import SwiftUI

// Sticker Library View
struct StickerLibraryView: View {
    @StateObject private var stickerManager = StickerManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory: String = "General"
    
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
                // Category Tabs
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
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Sticker Grid
                if stickerManager.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else if let selectedCat = stickerManager.categories.first(where: { $0.name == selectedCategory }) {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(selectedCat.stickers) { sticker in
                                StickerThumbnail(sticker: sticker) {
                                    onStickerSelected(sticker.url)
                                    dismiss()
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    Spacer()
                    Text("No stickers in this category")
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
            .background(Color.black)
            .navigationTitle("Stickers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
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
