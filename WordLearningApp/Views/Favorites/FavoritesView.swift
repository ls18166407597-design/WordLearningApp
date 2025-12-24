import SwiftUI

struct FavoritesView: View {
    @State private var items: [String] = []
    @Binding var selectedTab: RootTab
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.backgroundLight.ignoresSafeArea()
            
            if items.isEmpty {
                EmptyStateView(
                    icon: "star.slash",
                    title: "暂无收藏",
                    message: "点击单词详情页的星标按钮即可收藏单词",
                    actionTitle: "去学习",
                    action: {
                        // 触觉反馈
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = .learn
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // 使用List支持左滑删除
                List {
                    // 统计信息
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.warningOrange)
                            .font(.bodySmall)
                        
                        Text("已收藏 \(items.count) 个单词")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                        
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: SpacingStyle.md, leading: SpacingStyle.xl, bottom: 0, trailing: SpacingStyle.xl))
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : -10)
                    .animation(.easeOut(duration: 0.4), value: isAnimating)
                    
                    // 单词列表（带错开动画和左滑删除）
                    ForEach(Array(items.enumerated()), id: \.element) { index, word in
                        NavigationLink(destination: WordDetailView(word: word, examType: .cet4)) {
                            FavoriteWordCard(word: word)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: SpacingStyle.xs, leading: SpacingStyle.xl, bottom: SpacingStyle.xs, trailing: SpacingStyle.xl))
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                            .delay(Double(index) * 0.05),
                            value: isAnimating
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                // 触觉反馈 - 删除操作
                                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                unfavoriteWord(word)
                            } label: {
                                Label("取消收藏", systemImage: "star.slash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .transition(.opacity)
            }
        }
        .navigationTitle("收藏")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            reload()
            // 触发动画
            withAnimation {
                isAnimating = true
            }
        }
        .onDisappear {
            isAnimating = false
        }
    }

    private func reload() {
        items = LocalStorage.shared.getFavorites()
    }
    
    private func unfavoriteWord(_ word: String) {
        withAnimation {
            items.removeAll { $0 == word }
        }
        
        // 从收藏中移除
        var favorites = LocalStorage.shared.getFavorites()
        favorites.removeAll { $0 == word }
        LocalStorage.shared.saveFavorites(favorites)
    }
}

// MARK: - 收藏单词卡片
struct FavoriteWordCard: View {
    let word: String
    @State private var wordData: WordData?
    
    var body: some View {
        HStack(spacing: SpacingStyle.md) {
            // 星标图标
            Image(systemName: "star.fill")
                .foregroundColor(.warningOrange)
                .font(.titleSmall)
            
            // 单词信息
            VStack(alignment: .leading, spacing: SpacingStyle.xs) {
                Text(word)
                    .font(.bodyLarge.weight(.semibold))
                    .foregroundColor(.textPrimary)
                
                if let data = wordData {
                    if let phonetic = data.phonetic, !phonetic.isEmpty {
                        Text(phonetic)
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                    
                    if let cn = data.chineseDefinition, !cn.isEmpty {
                        Text(cn)
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }
                } else {
                    Text("加载中...")
                        .font(.bodySmall)
                        .foregroundColor(.textTertiary)
                }
            }
            
            Spacer()
            
            // 箭头
            Image(systemName: "chevron.right")
                .foregroundColor(.textTertiary)
                .font(.bodySmall)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SpacingStyle.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
        )
        .onAppear {
            loadWordData()
        }
    }
    
    private func loadWordData() {
        wordData = LocalStorage.shared.getWordData(word)
    }
}

