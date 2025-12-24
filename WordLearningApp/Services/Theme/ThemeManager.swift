//
//  ThemeManager.swift
//  WordLearningApp
//
//  主题管理器 - 管理应用主题（浅色/深色/自动）
//

import SwiftUI

// MARK: - 主题模式
enum AppThemeMode: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        case .system: return "跟随系统"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// MARK: - 主题管理器
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentMode: AppThemeMode {
        didSet {
            saveTheme()
        }
    }
    
    private let userDefaultsKey = "app_theme_mode"
    
    private init() {
        // 从UserDefaults加载主题设置
        if let savedMode = UserDefaults.standard.string(forKey: userDefaultsKey),
           let mode = AppThemeMode(rawValue: savedMode) {
            self.currentMode = mode
        } else {
            self.currentMode = .system
        }
    }
    
    // MARK: - 保存主题设置
    private func saveTheme() {
        UserDefaults.standard.set(currentMode.rawValue, forKey: userDefaultsKey)
    }
    
    // MARK: - 切换主题
    func setTheme(_ mode: AppThemeMode) {
        currentMode = mode
    }
    
    // MARK: - 获取当前ColorScheme
    func getColorScheme() -> ColorScheme? {
        return currentMode.colorScheme
    }
}

// MARK: - View扩展 - 应用主题
extension View {
    func applyTheme(_ themeManager: ThemeManager) -> some View {
        self.preferredColorScheme(themeManager.getColorScheme())
    }
}
