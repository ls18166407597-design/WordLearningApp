//
//  HomeView.swift
//  WordLearningApp
//
//  主页面
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: RootTab

    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var ttsService = TTSService.shared
    @State private var searchText = ""
    @State private var selectedExamType: ExamType = .cet4
    @State private var path = NavigationPath()
    @State private var showRedirectAlert = false
    @State private var redirectMessage = ""
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: SpacingStyle.xl) {
                    heroSection
                    searchModule
                    QuickLinksView(onSelectTab: { tab in
                        selectedTab = tab
                    })
                    
                    if !viewModel.recentHistory.isEmpty {
                        RecentHistoryView(history: viewModel.recentHistory) { word in
                            openWord(word)
                        }
                        .padding(.horizontal, SpacingStyle.xl)
                    }
                }
                .padding(.top, SpacingStyle.xl)
                .padding(.bottom, SpacingStyle.xl * 2)
            }
            .scrollDismissesKeyboard(.immediately)
            .simultaneousGesture(
                TapGesture().onEnded {
                    hideKeyboard()
                }
            )
            .background(
                LinearGradient(
                    colors: [Color.homeBackgroundTop, Color.homeBackgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("单词学习")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { w in
                WordDetailView(word: w, examType: selectedExamType)
            }
            .onAppear {
                viewModel.loadHistory()
            }
            .alert("自动跳转提示", isPresented: $showRedirectAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(redirectMessage)
            }
        }
    }
    
    private func searchWord() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        // 触觉反馈
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let w = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        
        // 异步查找原形
        Task {
            let original = await WordFormService.shared.findOriginalWord(for: w)
            
            // 如果输入的是变体，显示提示
            if original != w {
                let isGrammatical = await WordFormService.shared.isGrammaticalVariant(word: w)
                if isGrammatical {
                    redirectMessage = "已自动跳转到原形: \(original)\n（\(w) 是语法变体）"
                } else {
                    redirectMessage = "已自动跳转到: \(original)"
                }
                showRedirectAlert = true
            }
            
            // 跳转到原形
            await MainActor.run {
                openWord(original)
                searchText = ""
                viewModel.updateAutocomplete(prefix: "")
            }
        }
    }

    private func openWord(_ word: String) {
        let w = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !w.isEmpty else { return }
        path.append(w)
    }
}

// MARK: - QuickLinksView
struct QuickLinksView: View {
    let onSelectTab: (RootTab) -> Void
    @State private var pressedButton: RootTab?

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingStyle.lg) {
            Text("快速访问")
                .font(.titleSmall)
                .foregroundColor(.textPrimary)
                .padding(.horizontal, SpacingStyle.xl)
            
            HStack(spacing: SpacingStyle.md) {
                Button {
                    // 触觉反馈
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        pressedButton = .favorites
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        pressedButton = nil
                        onSelectTab(.favorites)
                    }
                } label: {
                    QuickLinkCard(
                        icon: "star.fill",
                        title: "收藏",
                        gradient: LinearGradient(
                            colors: [Color.orange.opacity(0.8), Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        isPressed: pressedButton == .favorites
                    )
                }
                .buttonStyle(.plain)
                
                Button {
                    // 触觉反馈
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        pressedButton = .history
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        pressedButton = nil
                        onSelectTab(.history)
                    }
                } label: {
                    QuickLinkCard(
                        icon: "tray.full.fill",
                        title: "词库",
                        gradient: LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        isPressed: pressedButton == .history
                    )
                }
                .buttonStyle(.plain)

                Button {
                    // 触觉反馈
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        pressedButton = .settings
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        pressedButton = nil
                        onSelectTab(.settings)
                    }
                } label: {
                    QuickLinkCard(
                        icon: "gearshape.fill",
                        title: "设置",
                        gradient: LinearGradient(
                            colors: [Color.gray.opacity(0.8), Color.gray],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        isPressed: pressedButton == .settings
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, SpacingStyle.xl)
        }
    }
}

struct QuickLinkCard: View {
    let icon: String
    let title: String
    let gradient: LinearGradient
    var isPressed: Bool = false
    
    var body: some View {
        VStack(spacing: SpacingStyle.md) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.white)
            Text(title)
                .font(.captionLarge)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SpacingStyle.xl)
        .background(gradient)
        .cornerRadius(CornerRadiusStyle.large)
        .shadow(
            color: ShadowStyle.medium.color,
            radius: ShadowStyle.medium.radius,
            x: ShadowStyle.medium.x,
            y: ShadowStyle.medium.y
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - RecentHistoryView
struct RecentHistoryView: View {
    let history: [String]
    let onWordTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingStyle.lg) {
            Text("最近查询")
                .font(.titleSmall)
                .foregroundColor(.textPrimary)
                .padding(.horizontal, SpacingStyle.xl)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SpacingStyle.md) {
                    ForEach(history.prefix(10), id: \.self) { word in
                        Button(action: {
                            onWordTap(word)
                        }) {
                            Text(word)
                                .font(.bodyMedium)
                                .padding(.horizontal, SpacingStyle.lg)
                                .padding(.vertical, SpacingStyle.sm)
                                .background(
                                    LinearGradient(
                                        colors: [Color.primaryBlue.opacity(0.15), Color.primaryBlue.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.primaryBlue)
                                .cornerRadius(CornerRadiusStyle.xlarge)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadiusStyle.xlarge)
                                        .stroke(Color.primaryBlue.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, SpacingStyle.xl)
            }
        }
    }
}

// MARK: - HomeView Components
private extension HomeView {
    var heroSection: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: CornerRadiusStyle.xlarge)
                .fill(
                    LinearGradient(
                        colors: [Color.heroCardStart, Color.heroCardEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 2)
                        .scaleEffect(1.3)
                        .offset(x: 120, y: -80)
                )
                .shadow(color: Color.primaryDark.opacity(0.4), radius: 20, x: 0, y: 12)
            
            VStack(alignment: .leading, spacing: SpacingStyle.md) {
                Text("AI 词伴 · 今日学习")
                    .font(.captionLarge)
                    .foregroundColor(Color.white.opacity(0.9))
                
                Text("发现单词的更多可能")
                    .font(.titleLarge.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                
                HStack(spacing: SpacingStyle.md) {
                    heroStatChip(title: "本地词库", value: "\(max(viewModel.recentHistory.count, storageWordCount)) 条")
                    heroStatChip(title: "今日任务", value: "15 min")
                }
                
            }
            .padding(SpacingStyle.xl)
        }
        .padding(.horizontal, SpacingStyle.xl)
    }
    
    var searchModule: some View {
        VStack(alignment: .leading, spacing: SpacingStyle.lg) {
            VStack(alignment: .leading, spacing: SpacingStyle.md) {
                Text("智能查词")
                    .font(.titleSmall.weight(.semibold))
                    .foregroundColor(.textPrimary)
                
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
                        .fill(Color.surfaceBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
                                .stroke(Color.outlineSoft, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 12)

                    HStack(spacing: SpacingStyle.md) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.primaryBlue)
                        
                        TextField("", text: $searchText, prompt: Text("输入单词、变形或短语").foregroundColor(.placeholderText))
                            .font(.bodyMedium)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onSubmit(searchWord)
                            .onChange(of: searchText) { _, newValue in
                                viewModel.updateAutocomplete(prefix: newValue)
                            }
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                viewModel.updateAutocomplete(prefix: "")
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        Button(action: searchWord) {
                            Image(systemName: "arrow.right")
                                .foregroundColor(.white)
                                .padding()
                                .background(LinearGradient(
                                    colors: [Color.primaryBlue, Color.primaryDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .clipShape(Circle())
                                .shadow(color: Color.primaryBlue.opacity(0.4), radius: 12, x: 0, y: 5)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, SpacingStyle.lg)
                    .padding(.vertical, SpacingStyle.md)
                }
            }
            
            if !viewModel.autocomplete.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.autocomplete, id: \.self) { w in
                        HStack(spacing: SpacingStyle.md) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(w)
                                    .font(.bodyMedium)
                                    .foregroundColor(.textPrimary)
                                Text("点击查看详情")
                                    .font(.captionSmall)
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer()
                            Button {
                                ttsService.speak(w)
                            } label: {
                                Image(systemName: ttsService.isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                                    .foregroundColor(.primaryBlue)
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                openWord(w)
                            } label: {
                                Image(systemName: "arrow.up.right")
                                    .foregroundColor(.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, SpacingStyle.lg)
                        .padding(.vertical, SpacingStyle.md)
                        
                        if w != viewModel.autocomplete.last {
                            Divider()
                                .padding(.leading, SpacingStyle.lg)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
                )
            }
            
            VStack(alignment: .leading, spacing: SpacingStyle.sm) {
                HStack {
                    Text("考试类型")
                        .font(.captionLarge.weight(.medium))
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text("匹配对应考纲风格")
                        .font(.captionSmall)
                        .foregroundColor(.textTertiary)
                }
                
                Picker("考试类型", selection: $selectedExamType) {
                    ForEach(ExamType.allCases, id: \.self) { examType in
                        Text(examType.displayName).tag(examType)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
                            .stroke(Color.white.opacity(0.1))
                    )
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 5)
            )
        }
        .padding(.horizontal, SpacingStyle.xl)
    }
    
    var storageWordCount: Int {
        LocalStorage.shared.getAllWords().count
    }
    
    func heroStatChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.captionSmall)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.titleSmall.weight(.semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, SpacingStyle.md)
        .padding(.vertical, SpacingStyle.sm)
        .background(Color.white.opacity(0.15))
        .cornerRadius(CornerRadiusStyle.medium)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(.learn))
    }
}


