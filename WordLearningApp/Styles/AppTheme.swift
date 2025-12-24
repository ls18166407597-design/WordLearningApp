//
//  AppTheme.swift
//  WordLearningApp
//
//  应用主题 - 统一的颜色、字体、样式
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - 颜色系统
extension Color {
    // 主色调
    static let primaryBlue = Color(red: 52/255, green: 152/255, blue: 219/255)  // #3498db
    static let primaryDark = Color(red: 41/255, green: 128/255, blue: 185/255)  // #2980b9
    static let homeBackgroundTop = Color(
        light: Color(red: 42/255, green: 93/255, blue: 177/255),
        dark: Color(red: 4/255, green: 8/255, blue: 20/255)
    )
    static let homeBackgroundBottom = Color(
        light: Color.backgroundLight,
        dark: Color(red: 15/255, green: 16/255, blue: 28/255)
    )
    static let heroCardStart = Color(
        light: Color(red: 57/255, green: 130/255, blue: 210/255),
        dark: Color(red: 26/255, green: 80/255, blue: 132/255)
    )
    static let heroCardEnd = Color(
        light: Color.primaryDark,
        dark: Color(red: 9/255, green: 30/255, blue: 64/255)
    )
    static let detailBackgroundTop = Color(
        light: Color.primaryDark.opacity(0.15),
        dark: Color(red: 5/255, green: 7/255, blue: 15/255)
    )
    static let detailBackgroundBottom = Color(
        light: Color.backgroundLight,
        dark: Color(red: 13/255, green: 14/255, blue: 24/255)
    )
    static let surfaceBackground = Color(
        light: Color.white,
        dark: Color(.secondarySystemBackground)
    )
    static let elevatedSurface = Color(
        light: Color.cardBackground,
        dark: Color(.tertiarySystemBackground)
    )
    static let placeholderText = Color(
        light: Color(.tertiaryLabel),
        dark: Color.white.opacity(0.55)
    )
    static let outlineSoft = Color(
        light: Color.white.opacity(0.4),
        dark: Color.white.opacity(0.08)
    )
    
    // 辅助色
    static let successGreen = Color(red: 39/255, green: 174/255, blue: 96/255)  // #27ae60
    static let warningOrange = Color(red: 243/255, green: 156/255, blue: 18/255) // #f39c12
    static let dangerRed = Color(red: 231/255, green: 76/255, blue: 60/255)     // #e74c3c
    static let infoBlue = Color(red: 52/255, green: 152/255, blue: 219/255)     // #3498db
    
    // 背景色（自适应暗黑模式）
    static let backgroundLight = Color(light: Color(red: 245/255, green: 247/255, blue: 250/255),
                                       dark: Color(red: 18/255, green: 18/255, blue: 18/255))
    static let cardBackground = Color(.systemBackground)
    
    // 文字色（自适应暗黑模式）
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    
    // 渐变色
    static let gradientStart = Color(red: 52/255, green: 152/255, blue: 219/255)
    static let gradientEnd = Color(red: 41/255, green: 128/255, blue: 185/255)
    
    // MARK: - 辅助方法：创建自适应颜色
    static func adaptive(light: Color, dark: Color) -> Color {
        return Color(light: light, dark: dark)
    }
}

// MARK: - Color扩展：支持浅色/深色模式
extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - 渐变样式
extension LinearGradient {
    static let primaryGradient = LinearGradient(
        colors: [.gradientStart, .gradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [Color.primaryBlue.opacity(0.1), Color.primaryBlue.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - 阴影样式
struct ShadowStyle {
    static let small = (color: Color.black.opacity(0.1), radius: CGFloat(5), x: CGFloat(0), y: CGFloat(2))
    static let medium = (color: Color.black.opacity(0.15), radius: CGFloat(10), x: CGFloat(0), y: CGFloat(4))
    static let large = (color: Color.black.opacity(0.2), radius: CGFloat(15), x: CGFloat(0), y: CGFloat(6))
}

// MARK: - 圆角样式
struct CornerRadiusStyle {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xlarge: CGFloat = 20
}

// MARK: - 间距样式
struct SpacingStyle {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

// MARK: - 字体样式
extension Font {
    static let titleLarge = Font.system(size: 32, weight: .bold)
    static let titleMedium = Font.system(size: 24, weight: .semibold)
    static let titleSmall = Font.system(size: 20, weight: .semibold)
    
    static let bodyLarge = Font.system(size: 18, weight: .regular)
    static let bodyMedium = Font.system(size: 16, weight: .regular)
    static let bodySmall = Font.system(size: 14, weight: .regular)
    
    static let captionLarge = Font.system(size: 12, weight: .medium)
    static let captionSmall = Font.system(size: 10, weight: .regular)
}

// MARK: - View扩展 - 通用修饰符
extension View {
    /// 卡片样式
    func cardStyle() -> some View {
        self
            .background(Color.cardBackground)
            .cornerRadius(CornerRadiusStyle.medium)
            .shadow(
                color: ShadowStyle.small.color,
                radius: ShadowStyle.small.radius,
                x: ShadowStyle.small.x,
                y: ShadowStyle.small.y
            )
    }
    
    /// 渐变卡片样式
    func gradientCardStyle() -> some View {
        self
            .background(LinearGradient.cardGradient)
            .cornerRadius(CornerRadiusStyle.medium)
            .shadow(
                color: ShadowStyle.medium.color,
                radius: ShadowStyle.medium.radius,
                x: ShadowStyle.medium.x,
                y: ShadowStyle.medium.y
            )
    }
    
    /// 主按钮样式
    func primaryButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .padding(.horizontal, SpacingStyle.lg)
            .padding(.vertical, SpacingStyle.md)
            .background(LinearGradient.primaryGradient)
            .cornerRadius(CornerRadiusStyle.medium)
            .shadow(
                color: ShadowStyle.small.color,
                radius: ShadowStyle.small.radius,
                x: ShadowStyle.small.x,
                y: ShadowStyle.small.y
            )
    }
    
    /// 次要按钮样式
    func secondaryButtonStyle() -> some View {
        self
            .foregroundColor(.primaryBlue)
            .padding(.horizontal, SpacingStyle.lg)
            .padding(.vertical, SpacingStyle.md)
            .background(Color.primaryBlue.opacity(0.1))
            .cornerRadius(CornerRadiusStyle.medium)
    }

    func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}
