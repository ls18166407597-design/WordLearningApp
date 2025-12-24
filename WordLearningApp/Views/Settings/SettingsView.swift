import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var baseURL: String = "https://dashscope.aliyuncs.com/compatible-mode/v1"
    @State private var model: String = "qwen-plus"
    @State private var statusText: String = ""
    @State private var showSuccessAlert = false
    
    @StateObject private var ttsService = TTSService.shared
    @State private var selectedVoice: TTSVoice = .usEnglish
    @State private var speechRate: Float = 0.5
    @State private var speechPitch: Float = 1.0
    @State private var speechVolume: Float = 1.0
    @State private var expandedMode: Bool = false
    @State private var ttsStatusText: String = ""
    @State private var showTTSSuccessAlert = false
    
    @EnvironmentObject var themeManager: ThemeManager

    private let store = LLMConfigStore.shared

    var body: some View {
        Form {
            // 主题设置
            Section {
                VStack(spacing: SpacingStyle.lg) {
                    Text("外观主题")
                        .font(.titleSmall)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: SpacingStyle.md) {
                        ForEach(AppThemeMode.allCases) { mode in
                            ThemeModeButton(
                                mode: mode,
                                isSelected: themeManager.currentMode == mode,
                                action: {
                                    // 触觉反馈
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        themeManager.setTheme(mode)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.vertical, SpacingStyle.sm)
            } header: {
                Label("主题", systemImage: "paintbrush.fill")
            }
            
            Section {
                SecureField("API Key", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)

                TextField("Base URL", text: $baseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)

                TextField("Model", text: $model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)

                Toggle(isOn: $expandedMode) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("扩展学习模式")
                        Text("开启后要求 AI 生成更多释义、短语和例句，适合深入学习。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: expandedMode) {
                    // 触觉反馈
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

                // 保存按钮（突出显示）
                Button(action: {
                    // 触觉反馈
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    save()
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                        Text("保存配置")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .background(LinearGradient.primaryGradient)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                // 状态提示（带图标和颜色）
                if !statusText.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.successGreen)
                        Text(statusText)
                            .font(.footnote)
                            .foregroundColor(.successGreen)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            } header: {
                Label("LLM 配置", systemImage: "brain.head.profile")
            }

            Section {
                Picker("语音", selection: $selectedVoice) {
                    ForEach(TTSVoice.allCases) { voice in
                        Text(voice.displayName).tag(voice)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedVoice) {
                    // 触觉反馈
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("语速")
                        Spacer()
                        Text(String(format: "%.1f", speechRate))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $speechRate, in: 0.1...1.0, step: 0.1)
                        .tint(.primaryBlue)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("音调")
                        Spacer()
                        Text(String(format: "%.1f", speechPitch))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $speechPitch, in: 0.5...2.0, step: 0.1)
                        .tint(.primaryBlue)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("音量")
                        Spacer()
                        Text(String(format: "%.1f", speechVolume))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $speechVolume, in: 0.0...1.0, step: 0.1)
                        .tint(.primaryBlue)
                }
                
                // 测试按钮（次要样式）
                Button(action: {
                    // 触觉反馈
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    testSpeech()
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "speaker.wave.2.fill")
                        Text("测试发音")
                        Spacer()
                    }
                    .foregroundColor(.primaryBlue)
                    .padding(.vertical, 8)
                    .background(Color.primaryBlue.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                // 保存按钮（主要样式）
                Button(action: {
                    // 触觉反馈
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    saveTTSConfig()
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                        Text("保存发音设置")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .background(LinearGradient.primaryGradient)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                // 重置按钮
                Button(action: {
                    // 触觉反馈
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    resetTTSConfig()
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.counterclockwise")
                        Text("恢复默认")
                        Spacer()
                    }
                    .foregroundColor(.textSecondary)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                // 状态提示
                if !ttsStatusText.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.successGreen)
                        Text(ttsStatusText)
                            .font(.footnote)
                            .foregroundColor(.successGreen)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            } header: {
                Label("发音设置", systemImage: "speaker.wave.3.fill")
            } footer: {
                Text("调整后点击\"测试发音\"试听效果，满意后点击\"保存发音设置\"")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .simultaneousGesture(
            TapGesture().onEnded {
                hideKeyboard()
            }
        )
        .navigationTitle("设置")
        .onAppear {
            load()
            loadTTSConfig()
        }
    }

    private func load() {
        let cfg = store.config
        apiKey = cfg.apiKey
        baseURL = cfg.baseURL
        model = cfg.model
        expandedMode = cfg.expandedMode
        statusText = ""
    }

    private func save() {
        let cfg = LLMConfig(
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
            baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines),
            model: model.trimmingCharacters(in: .whitespacesAndNewlines),
            expandedMode: expandedMode
        )
        store.update(cfg)
        
        withAnimation {
            statusText = "配置已保存"
        }
        
        // 3秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                statusText = ""
            }
        }
    }
    
    private func loadTTSConfig() {
        selectedVoice = ttsService.config.voice
        speechRate = ttsService.config.rate
        speechPitch = ttsService.config.pitch
        speechVolume = ttsService.config.volume
    }
    
    private func saveTTSConfig() {
        var config = ttsService.config
        config.voice = selectedVoice
        config.rate = speechRate
        config.pitch = speechPitch
        config.volume = speechVolume
        ttsService.updateConfig(config)
        
        withAnimation {
            ttsStatusText = "发音设置已保存"
        }
        
        // 3秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                ttsStatusText = ""
            }
        }
    }
    
    private func resetTTSConfig() {
        selectedVoice = .usEnglish
        speechRate = 0.5
        speechPitch = 1.0
        speechVolume = 1.0
        
        withAnimation {
            ttsStatusText = "已恢复默认设置"
        }
        
        // 3秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                ttsStatusText = ""
            }
        }
    }
    
    private func testSpeech() {
        // 临时应用设置进行测试
        var testConfig = ttsService.config
        testConfig.voice = selectedVoice
        testConfig.rate = speechRate
        testConfig.pitch = speechPitch
        testConfig.volume = speechVolume
        ttsService.updateConfig(testConfig)
        
        // 测试发音
        ttsService.speak("Hello, this is a test of the text to speech system.")
    }
}

// MARK: - 主题模式按钮
struct ThemeModeButton: View {
    let mode: AppThemeMode
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            VStack(spacing: SpacingStyle.sm) {
                ZStack {
                    Circle()
                        .fill(isSelected ? LinearGradient.primaryGradient : LinearGradient(colors: [Color.gray.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 60, height: 60)
                        .shadow(
                            color: isSelected ? Color.primaryBlue.opacity(0.3) : Color.clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    Image(systemName: mode.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : .textSecondary)
                }
                
                Text(mode.displayName)
                    .font(.captionLarge)
                    .foregroundColor(isSelected ? .primaryBlue : .textSecondary)
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
    }
}

