//
//  ZZAchievementsViewModel.swift
//  Moro Drift
//
//  Created by Dias Atudinov on 21.10.2025.
//


import SwiftUI

class ZZAchievementsViewModel: ObservableObject {
    
    @Published var achievements: [NEGAchievement] = [
        NEGAchievement(image: "achieve1ImageMD", title: "achieve1TextMD", isAchieved: false),
        NEGAchievement(image: "achieve2ImageMD", title: "achieve2TextMD", isAchieved: false),
        NEGAchievement(image: "achieve3ImageMD", title: "achieve3TextMD", isAchieved: false),
        NEGAchievement(image: "achieve4ImageMD", title: "achieve4TextMD", isAchieved: false),
        NEGAchievement(image: "achieve5ImageMD", title: "achieve5TextMD", isAchieved: false),
    ] {
        didSet {
            saveAchievementsItem()
        }
    }
        
    init() {
        loadAchievementsItem()
    }
    
    private let userDefaultsAchievementsKey = "achievementsKeyMD"
    
    func achieveToggle(_ achive: NEGAchievement) {
        guard let index = achievements.firstIndex(where: { $0.id == achive.id })
        else {
            return
        }
        achievements[index].isAchieved.toggle()
        
    }
   
    
    
    func saveAchievementsItem() {
        if let encodedData = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encodedData, forKey: userDefaultsAchievementsKey)
        }
        
    }
    
    func loadAchievementsItem() {
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsAchievementsKey),
           let loadedItem = try? JSONDecoder().decode([NEGAchievement].self, from: savedData) {
            achievements = loadedItem
        } else {
            print("No saved data found")
        }
    }
}

struct NEGAchievement: Codable, Hashable, Identifiable {
    var id = UUID()
    var image: String
    var title: String
    var isAchieved: Bool
}
