import SwiftUI

struct HistoryView: View {
    @State private var items: [String] = []
    @State private var query: String = ""
    @State private var showClearAlert = false
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.backgroundLight.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 自定义搜索框
                HStack(spacing: SpacingStyle.md) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textSecondary)
                            .font(.bodyMedium)
                        
                        TextField("搜索词库...", text: $query)
                            .font(.bodyMedium)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        if !query.isEmpty {
                            Button(action: {
                                // 触觉反馈 - 准备生成器
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    query = ""
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.textSecondary)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, SpacingStyle.lg)
                    .padding(.vertical, SpacingStyle.md)
                    .background(Color.cardBackground)
                    .cornerRadius(CornerRadiusStyle.medium)
                    .shadow(
                        color: ShadowStyle.small.color,
                        radius: ShadowStyle.small.radius,
                        x: ShadowStyle.small.x,
                        y: ShadowStyle.small.y
                    )
                }
                .padding(.horizontal, SpacingStyle.xl)
                .padding(.vertical, SpacingStyle.md)
                .background(Color.backgroundLight)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : -10)
                .animation(.easeOut(duration: 0.4), value: isAnimating)
                
                if filteredItems.isEmpty {
                    EmptyStateView(
                        icon: items.isEmpty ? "tray" : "magnifyingglass",
                        title: items.isEmpty ? "词库为空" : "未找到匹配的单词",
                        message: items.isEmpty ? "学习过的单词会自动保存到词库" : "试试搜索其他单词"
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // 使用List支持左滑删除
                    List {
                        // 统计信息
                        HStack {
                            Image(systemName: "tray.full.fill")
                                .foregroundColor(.primaryBlue)
                                .font(.bodySmall)
                            
                            Text("共 \(filteredItems.count) 个单词")
                                .font(.bodyMedium)
                                .foregroundColor(.textSecondary)
                            
                            Spacer()
                            
                            if !items.isEmpty {
                                Button(action: {
                                    // 触觉反馈
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    showClearAlert = true
                                }) {
                                    Text("清空")
                                        .font(.bodySmall)
                                        .foregroundColor(.dangerRed)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: SpacingStyle.sm, leading: SpacingStyle.xl, bottom: 0, trailing: SpacingStyle.xl))
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : -10)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: isAnimating)
                        
                        // 单词列表（按首字母分组）
                        ForEach(Array(groupedWords.keys.sorted().enumerated()), id: \.element) { groupIndex, letter in
                            Section {
                                ForEach(Array((groupedWords[letter] ?? []).enumerated()), id: \.element) { wordIndex, word in
                                    NavigationLink(destination: WordDetailView(word: word, examType: .cet4)) {
                                        HistoryWordCard(word: word)
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: SpacingStyle.xs, leading: SpacingStyle.xl, bottom: SpacingStyle.xs, trailing: SpacingStyle.xl))
                                    .opacity(isAnimating ? 1 : 0)
                                    .offset(y: isAnimating ? 0 : 20)
                                    .animation(
                                        .spring(response: 0.6, dampingFraction: 0.8)
                                        .delay(0.2 + Double(groupIndex) * 0.05 + Double(wordIndex) * 0.03),
                                        value: isAnimating
                                    )
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            // 触觉反馈 - 删除操作
                                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                            deleteWord(word)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                Text(letter)
                                    .font(.titleSmall.weight(.bold))
                                    .foregroundColor(.primaryBlue)
                                    .listRowInsets(EdgeInsets(top: SpacingStyle.md, leading: SpacingStyle.xl, bottom: 0, trailing: SpacingStyle.xl))
                                    .opacity(isAnimating ? 1 : 0)
                                    .offset(x: isAnimating ? 0 : -20)
                                    .animation(
                                        .easeOut(duration: 0.4)
                                        .delay(0.2 + Double(groupIndex) * 0.05),
                                        value: isAnimating
                                    )
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.immediately)
                    .transition(.opacity)
                }
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                hideKeyboard()
            }
        )
        .navigationTitle("词库")
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
        .alert("清空词库", isPresented: $showClearAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                // 触觉反馈 - 警告类型
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                clearAll()
            }
        } message: {
            Text("确定要清空所有单词吗？此操作不可恢复。")
        }
    }

    private var filteredItems: [String] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return items }
        return items.filter { $0.lowercased().contains(q) }
    }
    
    private var groupedWords: [String: [String]] {
        Dictionary(grouping: filteredItems) { word in
            String(word.prefix(1).uppercased())
        }
    }

    private func reload() {
        items = LocalStorage.shared.getAllWords()
    }
    
    private func deleteWord(_ word: String) {
        withAnimation {
            items.removeAll { $0 == word }
        }
        
        // 删除本地数据
        let storage = LocalStorage.shared
        storage.deleteWordData(word)
        
        // 从收藏中移除
        var favorites = storage.getFavorites()
        favorites.removeAll { $0 == word }
        storage.saveFavorites(favorites)
        
        // 从历史中移除
        var history = storage.getHistory()
        history.removeAll { $0 == word }
        storage.saveHistory(history)
    }

    private func clearAll() {
        withAnimation {
            items = []
        }
        
        let storage = LocalStorage.shared
        storage.deleteAllWordData()
        storage.saveFavorites([])
        storage.saveHistory([])
    }
}

// MARK: - 词库单词卡片
struct HistoryWordCard: View {
    let word: String
    @State private var wordData: WordData?
    
    var body: some View {
        HStack(spacing: SpacingStyle.md) {
            // 单词信息
            VStack(alignment: .leading, spacing: SpacingStyle.xs) {
                Text(word.capitalized)
                    .font(.bodyLarge.weight(.semibold))
                    .foregroundColor(.textPrimary)
                
                if let data = wordData {
                    HStack(spacing: SpacingStyle.sm) {
                        if let phonetic = data.phonetic, !phonetic.isEmpty {
                            Text(phonetic)
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                        
                        if let pos = data.partOfSpeech, !pos.isEmpty {
                            Text(pos)
                                .font(.captionLarge)
                                .foregroundColor(.primaryBlue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primaryBlue.opacity(0.1))
                                .cornerRadius(4)
                        }
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

