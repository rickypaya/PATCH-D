//
//  StickerManager.swift
//  PATCH'D
//

import SwiftUI

// Sticker Models
struct StickerCategory: Identifiable {
    let id = UUID()
    let name: String
    let folderName: String
    var stickers: [StickerItem] = []
}

struct StickerItem: Identifiable {
    let id = UUID()
    let url: String
    let category: String
}

// Sticker Manager
class StickerManager: ObservableObject {
    static let shared = StickerManager()
    
    @Published var categories: [StickerCategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dbManager = CollageDBManager.shared
    
    private init() {
        Task {
            await loadStickers()
        }
    }
    
    // Load stickers from Supabase Storage
    func loadStickers() async {
        isLoading = true
        errorMessage = nil
        
        // Define category folders from your Supabase structure
        let categoryFolders = [
            ("Animals", "Stickers/Animals"),
            ("Creative", "Stickers/Creative"),
            ("Education", "Stickers/Education"),
            ("Entertainment", "Stickers/Entertainment"),
            ("Fitness", "Stickers/Fitness"),
            ("Food", "Stickers/Food"),
            ("Home", "Stickers/Home"),
            ("Lifestyle", "Stickers/Lifestyle"),
            ("Memories", "Stickers/Memories"),
            ("Nature", "Stickers/Nature"),
            ("Social", "Stickers/Social"),
            ("Travel", "Stickers/Travel"),
            ("Urban", "Stickers/Urban"),
            ("General", "Stickers/_General")
        ]
        
        var loadedCategories: [StickerCategory] = []
        
        for (name, folder) in categoryFolders {
            do {
                let stickers = try await fetchStickersFromFolder(folder: folder, categoryName: name)
                var category = StickerCategory(name: name, folderName: folder)
                category.stickers = stickers
                
                // Always include Food category, even if empty
                // For other categories, only include if they have stickers
                if name == "Food" || !stickers.isEmpty {
                    loadedCategories.append(category)
                }
            } catch {
                print("Failed to load category \(name): \(error)")
                
                // Still include Food category even if loading failed
                if name == "Food" {
                    let emptyCategory = StickerCategory(name: name, folderName: folder)
                    loadedCategories.append(emptyCategory)
                }
            }
        }
        
        // Sort: Food first, then by sticker count (most to least), then alphabetically
        loadedCategories.sort { cat1, cat2 in
            // Food category always comes first
            if cat1.name == "Food" { return true }
            if cat2.name == "Food" { return false }
            
            // Sort by sticker count (most to least)
            if cat1.stickers.count != cat2.stickers.count {
                return cat1.stickers.count > cat2.stickers.count
            }
            
            // If sticker counts are equal, sort alphabetically
            return cat1.name < cat2.name
        }
        
        categories = loadedCategories
        isLoading = false
    }
    
    private func fetchStickersFromFolder(folder: String, categoryName: String) async throws -> [StickerItem] {
        // List all files in the folder from Supabase Storage
        let files = try await dbManager.listFilesInFolder(bucket: "patchd-storage", folder: folder)
        
        var stickers: [StickerItem] = []
        
        for file in files {
            // Only include PNG files
            if file.hasSuffix(".png") {
                let fullPath = "\(folder)/\(file)"
                let publicURL = try dbManager.getPublicURL(bucket: "patchd-storage", path: fullPath)
                
                let sticker = StickerItem(
                    url: publicURL,
                    category: categoryName
                )
                stickers.append(sticker)
            }
        }
        
        return stickers
    }
}
