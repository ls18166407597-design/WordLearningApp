//
//  WordLearningApp.swift
//  WordLearningApp
//
//  应用入口
//

import SwiftUI

@main
struct WordLearningApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(themeManager)
                .applyTheme(themeManager)
        }
    }
}


