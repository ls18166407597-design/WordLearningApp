//
//  EmptyStateView.swift
//  WordLearningApp
//
//  空状态视图组件
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @State private var isAnimating = false
    @State private var iconScale: CGFloat = 0.8
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: SpacingStyle.xl) {
            Spacer()
            
            // 图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.primaryBlue.opacity(0.1), Color.primaryBlue.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(iconScale)
                
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(.primaryBlue.opacity(0.6))
                    .scaleEffect(iconScale)
            }
            .opacity(isAnimating ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isAnimating)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: iconScale)
            
            // 文字
            VStack(spacing: SpacingStyle.sm) {
                Text(title)
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                
                Text(message)
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SpacingStyle.xxl)
            }
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 10)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: isAnimating)
            
            // 操作按钮（可选）
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    // 触觉反馈
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    
                    action()
                }) {
                    Text(actionTitle)
                        .font(.bodyMedium.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, SpacingStyle.xxl)
                        .padding(.vertical, SpacingStyle.md)
                        .background(LinearGradient.primaryGradient)
                        .cornerRadius(CornerRadiusStyle.medium)
                        .shadow(
                            color: Color.primaryBlue.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                }
                .padding(.top, SpacingStyle.md)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 10)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: isAnimating)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
            // 图标呼吸动画
            withAnimation {
                iconScale = 1.0
            }
        }
    }
}

// MARK: - Preview
struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView(
            icon: "star.slash",
            title: "暂无收藏",
            message: "点击单词详情页的星标按钮即可收藏",
            actionTitle: "去学习",
            action: { print("Go to learn") }
        )
    }
}
