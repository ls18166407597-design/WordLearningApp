import SwiftUI

struct WordDetailView: View {
    let word: String
    let examType: ExamType

    @StateObject private var viewModel = WordDetailViewModel()
    @StateObject private var ttsService = TTSService.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SpacingStyle.xl) {
                hero
                    .padding(.horizontal, SpacingStyle.xl)
                    .padding(.top, SpacingStyle.xl)
                
                VStack(alignment: .leading, spacing: SpacingStyle.lg) {
                    if viewModel.isLoading {
                        generationIndicator
                    }
                    
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.dangerRed)
                            .font(.bodySmall)
                            .padding(SpacingStyle.lg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.dangerRed.opacity(0.1))
                            .cornerRadius(CornerRadiusStyle.medium)
                    }
                    
                    if let d = viewModel.wordData {
                        basicsSection(d)
                        wordFormsSection(d)
                        meaningsSection(d)
                        phrasesSection(d)
                        examplesSection(d)
                        memoryTipsSection(d)
                        confusingSection(d)
                        etymologySection(d)
                    } else if !viewModel.isLoading && viewModel.errorMessage.isEmpty {
                        shimmeringCard(title: "暂无内容，试试其他单词？")
                    }
                }
                .padding(.horizontal, SpacingStyle.xl)
                .padding(.bottom, SpacingStyle.xxl)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(light: Color.primaryDark.opacity(0.15), dark: Color(red: 10/255, green: 15/255, blue: 25/255)),
                    Color.backgroundLight
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(word: word, examType: examType)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleFavorite(word: word)
                } label: {
                    Image(systemName: viewModel.isFavorite(word: word) ? "star.fill" : "star")
                        .foregroundColor(viewModel.isFavorite(word: word) ? .warningOrange : .textSecondary)
                }
            }
        }
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadiusStyle.xlarge)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(light: Color.primaryBlue, dark: Color(red: 30/255, green: 90/255, blue: 150/255)),
                            Color(light: Color.primaryDark, dark: Color(red: 20/255, green: 60/255, blue: 100/255))
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    VStack {
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 1)
                        Spacer()
                    }
                )
                .shadow(color: Color.primaryDark.opacity(0.35), radius: 20, x: 0, y: 12)
            
            VStack(alignment: .leading, spacing: SpacingStyle.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: SpacingStyle.sm) {
                        HStack(spacing: SpacingStyle.sm) {
                            Text(word.capitalized)
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(.white)

                            if viewModel.isCacheHit {
                                Text("已缓存")
                                    .font(.captionSmall.weight(.semibold))
                                    .foregroundColor(Color.white.opacity(0.85))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.18))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        if let phonetic = viewModel.wordData?.phonetic {
                            Text(phonetic)
                                .font(.titleSmall)
                                .foregroundColor(Color.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: SpacingStyle.sm) {
                        Button {
                            ttsService.speak(word)
                        } label: {
                            Image(systemName: ttsService.isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundColor(.primaryBlue)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                HStack(spacing: SpacingStyle.md) {
                    heroChip(title: "考试", value: examType.displayName)
                    let count = viewModel.wordData?.meanings.count ?? 0
                    heroChip(title: "释义", value: count > 0 ? "\(count) 条" : "生成后查看")
                    heroChip(title: "状态", value: viewModel.isFavorite(word: word) ? "已收藏" : "未收藏")
                }
            }
            .padding(SpacingStyle.xl)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.titleSmall)
            .foregroundColor(.textPrimary)
    }

    private func basicsSection(_ d: WordData) -> some View {
        VStack(alignment: .leading, spacing: SpacingStyle.md) {
            sectionTitle("基本信息")

            VStack(alignment: .leading, spacing: SpacingStyle.md) {
                if let phonetic = d.phonetic, !phonetic.isEmpty {
                    HStack(spacing: SpacingStyle.md) {
                        Image(systemName: "speaker.wave.1")
                            .foregroundColor(.primaryBlue)
                            .font(.bodySmall)
                        Text(phonetic)
                            .font(.bodyMedium)
                            .foregroundColor(.textPrimary)
                        Spacer()
                    }
                }
                
                if let pos = d.partOfSpeech, !pos.isEmpty {
                    HStack(spacing: SpacingStyle.sm) {
                        Image(systemName: "text.alignleft")
                            .foregroundColor(.primaryBlue)
                            .font(.bodySmall)
                        Text("词性：")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                        Text(pos)
                            .font(.bodyMedium)
                            .foregroundColor(.textPrimary)
                    }
                }
                
                if let cn = d.chineseDefinition, !cn.isEmpty {
                    HStack(alignment: .top, spacing: SpacingStyle.sm) {
                        Image(systemName: "doc.text")
                            .foregroundColor(.primaryBlue)
                            .font(.bodySmall)
                        Text("释义：")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                        Text(cn)
                            .font(.bodyMedium)
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SpacingStyle.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
                    .fill(Color.cardBackground)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
            )
        }
    }

    private func meaningsSection(_ d: WordData) -> some View {
        VStack(alignment: .leading, spacing: SpacingStyle.md) {
            sectionTitle("释义精要")
            
            VStack(spacing: SpacingStyle.md) {
                ForEach(Array(d.meanings.enumerated()), id: \.1.id) { index, meaning in
                    VStack(alignment: .leading, spacing: SpacingStyle.sm) {
                        HStack {
                            Text(String(format: "#%02d", index + 1))
                                .font(.captionSmall.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.primaryBlue.opacity(0.8))
                                .cornerRadius(6)
                            
                            Text(meaning.partOfSpeech.uppercased())
                                .font(.captionSmall)
                                .foregroundColor(.textSecondary)
                            Spacer()
                        }
                        
                        Text(meaning.definition)
                            .font(.bodyMedium.weight(.medium))
                            .foregroundColor(.textPrimary)
                        
                        if let cn = meaning.chineseDefinition, !cn.isEmpty {
                            Text(cn)
                                .foregroundColor(.textSecondary)
                                .font(.bodySmall)
                        }
                        
                        if let ex = meaning.example, !ex.isEmpty {
                            VStack(alignment: .leading, spacing: SpacingStyle.xs) {
                                Text("例句 · Exam Ready")
                                    .font(.captionSmall)
                                    .foregroundColor(.primaryBlue)
                                Text(ex)
                                    .font(.bodySmall.italic())
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(SpacingStyle.lg)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
                            .fill(Color.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
                                    .stroke(Color.primaryBlue.opacity(0.08), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
                    )
                }
            }
        }
    }

    private func phrasesSection(_ d: WordData) -> some View {
        VStack(alignment: .leading, spacing: SpacingStyle.md) {
            sectionTitle("常考短语")
            
            if d.phrases.isEmpty {
                emptyCard
            } else {
                VStack(spacing: SpacingStyle.md) {
                    ForEach(d.phrases) { p in
                        VStack(alignment: .leading, spacing: SpacingStyle.xs) {
                            HStack {
                                Text(p.phrase)
                                    .font(.bodyMedium.weight(.semibold))
                                    .foregroundColor(.primaryBlue)
                                Spacer()
                                Text("高频")
                                    .font(.captionSmall)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.primaryBlue.opacity(0.8))
                                    .cornerRadius(6)
                            }
                            Text(p.meaning)
                                .foregroundColor(.textSecondary)
                                .font(.bodySmall)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(SpacingStyle.lg)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
                                .fill(Color.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
                        )
                    }
                }
            }
        }
    }

    private func examplesSection(_ d: WordData) -> some View {
        VStack(alignment: .leading, spacing: SpacingStyle.md) {
            sectionTitle("例句")
            
            if d.examples.isEmpty {
                emptyCard
            } else {
                VStack(spacing: SpacingStyle.md) {
                    ForEach(d.examples) { e in
                        VStack(alignment: .leading, spacing: SpacingStyle.sm) {
                            HStack(alignment: .top, spacing: SpacingStyle.xs) {
                                Image(systemName: "quote.opening")
                                    .font(.captionSmall)
                                    .foregroundColor(.primaryBlue)
                                    .offset(y: 2)
                                
                                Text(e.sentence)
                                    .font(.bodyMedium)
                                    .foregroundColor(.textPrimary)
                            }
                            
                            if let t = e.translation, !t.isEmpty {
                                Text(t)
                                    .foregroundColor(.textSecondary)
                                    .font(.bodySmall)
                                    .padding(.leading, SpacingStyle.lg)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(SpacingStyle.lg)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
                                .fill(Color.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
                        )
                    }
                }
            }
        }
    }

    private func memoryTipsSection(_ d: WordData) -> some View {
        VStack(alignment: .leading, spacing: SpacingStyle.md) {
            sectionTitle("记忆技巧")
            
            let tips = d.memoryTips ?? []
            if tips.isEmpty {
                Text("暂无")
                    .foregroundColor(.textSecondary)
                    .font(.bodySmall)
                    .padding(SpacingStyle.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
            } else {
                VStack(spacing: SpacingStyle.md) {
                    ForEach(tips) { t in
                        VStack(alignment: .leading, spacing: SpacingStyle.sm) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.warningOrange)
                                    .font(.bodySmall)
                                
                                Text(t.type)
                                    .font(.captionLarge)
                                    .foregroundColor(.warningOrange)
                                    .padding(.horizontal, SpacingStyle.sm)
                                    .padding(.vertical, 2)
                                    .background(Color.warningOrange.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            
                            Text(t.content)
                                .font(.bodyMedium)
                                .foregroundColor(.textPrimary)
                            
                            if let a = t.association, !a.isEmpty {
                                Text(a)
                                    .foregroundColor(.textSecondary)
                                    .font(.bodySmall)
                                    .italic()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(SpacingStyle.lg)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
                                .fill(Color.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
                        )
                    }
                }
            }
        }
    }

    private func confusingSection(_ d: WordData) -> some View {
        VStack(alignment: .leading, spacing: SpacingStyle.md) {
            sectionTitle("易混淆")
            
            let items = d.confusingWords ?? []
            if items.isEmpty {
                emptyCard
            } else {
                VStack(spacing: SpacingStyle.md) {
                    ForEach(items) { c in
                        VStack(alignment: .leading, spacing: SpacingStyle.md) {
                            // 标题：显示所有易混淆的单词
                            HStack(spacing: SpacingStyle.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.warningOrange)
                                    .font(.bodySmall)
                                
                                ForEach(c.words, id: \.self) { word in
                                    Text(word)
                                        .font(.bodyMedium.weight(.semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, SpacingStyle.md)
                                        .padding(.vertical, SpacingStyle.xs)
                                        .background(Color.primaryBlue)
                                        .clipShape(Capsule())
                                }
                            }
                            
                            // 区别说明
                            Text("区别要点")
                                .font(.captionLarge.weight(.semibold))
                                .foregroundColor(.textSecondary)
                            
                            // 解析diff字段，按行分割
                            let lines = c.diff.components(separatedBy: "\n")
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }
                            
                            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                                HStack(alignment: .top, spacing: SpacingStyle.sm) {
                                    // 序号
                                    Text("\(index + 1).")
                                        .font(.bodyMedium.weight(.semibold))
                                        .foregroundColor(.primaryBlue)
                                        .frame(width: 20, alignment: .trailing)
                                    
                                    // 内容
                                    VStack(alignment: .leading, spacing: SpacingStyle.xs) {
                                        // 检查是否有冒号分隔（单词: 说明）
                                        if let colonRange = line.range(of: ":") ?? line.range(of: "：") {
                                            let word = String(line[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                                            let description = String(line[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                                            
                                            // 单词标签
                                            Text(word)
                                                .font(.captionLarge.weight(.semibold))
                                                .foregroundColor(.primaryBlue)
                                                .padding(.horizontal, SpacingStyle.sm)
                                                .padding(.vertical, 2)
                                                .background(Color.primaryBlue.opacity(0.1))
                                                .clipShape(Capsule())
                                            
                                            // 说明文字
                                            Text(description)
                                                .font(.bodySmall)
                                                .foregroundColor(.textPrimary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        } else {
                                            // 没有冒号，直接显示整行
                                            Text(line)
                                                .font(.bodySmall)
                                                .foregroundColor(.textPrimary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            
                            // 例句（如果有）
                            if let example = c.example, !example.isEmpty, example != "暂无" {
                                VStack(alignment: .leading, spacing: SpacingStyle.xs) {
                                    Text("例句")
                                        .font(.captionLarge.weight(.semibold))
                                        .foregroundColor(.textSecondary)
                                    
                                    Text(example)
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                        .italic()
                                }
                                .padding(.top, SpacingStyle.xs)
                            }
                            
                            // 记忆技巧（如果有）
                            if let memory = c.memory, !memory.isEmpty, memory != "暂无" {
                                HStack(alignment: .top, spacing: SpacingStyle.xs) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.warningOrange)
                                        .font(.captionSmall)
                                    
                                    Text(memory)
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.top, SpacingStyle.xs)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(SpacingStyle.lg)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
                                .fill(Color.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
                        )
                    }
                }
            }
        }
    }

    private func wordFormsSection(_ d: WordData) -> some View {
        VStack(alignment: .leading, spacing: SpacingStyle.md) {
            sectionTitle("词形与派生词")
            
            Text("包含语法变体（复数、时态等）和词性派生词")
                .font(.captionLarge)
                .foregroundColor(.textSecondary)
            
            // 优先使用 wordFormsWithLabels
            if let formsWithLabels = d.wordFormsWithLabels, !formsWithLabels.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: SpacingStyle.md)], spacing: SpacingStyle.md) {
                    ForEach(formsWithLabels) { form in
                        // 跳过和原词相同的语法变体
                        if form.isGrammatical && form.word.lowercased() == d.word.lowercased() {
                            EmptyView()
                        } else {
                            wordFormTag(form: form)
                        }
                    }
                }
            } else if let forms = d.wordForms, !forms.isEmpty {
                // 兼容旧格式
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: SpacingStyle.md)], spacing: SpacingStyle.md) {
                    ForEach(forms.filter { !$0.isEmpty && $0.lowercased() != d.word.lowercased() }, id: \.self) { form in
                        NavigationLink(destination: WordDetailView(word: form, examType: examType)) {
                            Text(form)
                                .font(.bodyMedium.weight(.semibold))
                                .foregroundColor(.textPrimary)
                                .padding(SpacingStyle.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .cardStyle()
                        }
                    }
                }
            } else {
                Text("暂无")
                    .foregroundColor(.textSecondary)
                    .font(.bodySmall)
                    .padding(SpacingStyle.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
            }
        }
    }
    
    // 词形标签组件
    private func wordFormTag(form: WordFormLabel) -> some View {
        Group {
            if form.isGrammatical {
                // 语法变体：灰色，不可点击
                VStack(alignment: .leading, spacing: 4) {
                    Text(form.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(form.word)
                        .font(.subheadline.weight(.semibold))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .overlay(
                    Text("仅语法变化")
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray)
                        .cornerRadius(4)
                        .offset(x: 5, y: -5),
                    alignment: .topTrailing
                )
            } else {
                // 词性变体：蓝色，可点击
                NavigationLink(destination: WordDetailView(word: form.word, examType: examType)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(form.label)
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(form.word)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func etymologySection(_ d: WordData) -> some View {
        VStack(alignment: .leading, spacing: SpacingStyle.md) {
            sectionTitle("词源")

            let summary = primaryEtymologyText(for: d)
            if summary.isEmpty {
                emptyCard
            } else {
                HStack(alignment: .top, spacing: SpacingStyle.sm) {
                    Image(systemName: "book.closed")
                        .foregroundColor(.primaryBlue)
                        .font(.bodySmall)
                    
                    Text(summary)
                        .font(.bodyMedium)
                        .foregroundColor(.textPrimary)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(SpacingStyle.lg)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
                )
            }
        }
    }
}

// MARK: - Helper Views
private extension WordDetailView {
    func primaryEtymologyText(for data: WordData) -> String {
        let summary = (data.etymology ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let details = (data.etymologyDetails ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        // User requirement: only one paragraph.
        // Prefer `etymology` (matches local words dataset). Use details only as fallback.
        if !summary.isEmpty { return summary }
        if !details.isEmpty { return details }
        return ""
    }
    
    var generationIndicator: some View {
        HStack(spacing: SpacingStyle.md) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 52, height: 52)
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }
            VStack(alignment: .leading, spacing: SpacingStyle.xs) {
                Text("AI 正在生成")
                    .font(.bodyMedium.weight(.semibold))
                    .foregroundColor(.white)
                Text("根据所选考试难度构建释义、例句等内容…")
                    .font(.captionSmall)
                    .foregroundColor(Color.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(SpacingStyle.lg)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.primaryBlue, Color.primaryDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadiusStyle.large)
        .shadow(color: Color.primaryDark.opacity(0.25), radius: 16, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.25), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.plusLighter)
                .opacity(0.4)
        )
        .mask(
            RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
        )
    }

    func shimmeringCard(title: String) -> some View {
        RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
            .fill(Color.cardBackground)
            .frame(maxWidth: .infinity, minHeight: 120)
            .overlay(
                Text(title)
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .padding()
            )
            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
            .redacted(reason: .placeholder)
    }

    func heroChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.captionSmall)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.bodyMedium.weight(.semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, SpacingStyle.md)
        .padding(.vertical, SpacingStyle.sm)
        .background(Color.white.opacity(0.15))
        .cornerRadius(CornerRadiusStyle.medium)
    }

    var emptyCard: some View {
        RoundedRectangle(cornerRadius: CornerRadiusStyle.large)
            .fill(Color.cardBackground)
            .frame(maxWidth: .infinity, minHeight: 90)
            .overlay(
                Text("暂无")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            )
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}
