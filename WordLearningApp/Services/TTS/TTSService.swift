//
//  TTSService.swift
//  WordLearningApp
//
//  文本转语音服务 - 使用AVFoundation实现
//  完全本地化，无需网络
//

import Foundation
import AVFoundation

// MARK: - 发音配置
struct TTSConfig: Codable {
    var voice: TTSVoice = .usEnglish
    var rate: Float = 0.5  // 语速：0.0-1.0
    var pitch: Float = 1.0  // 音调：0.5-2.0
    var volume: Float = 1.0  // 音量：0.0-1.0
}

// MARK: - 语音选项
enum TTSVoice: String, CaseIterable, Identifiable, Codable {
    case usEnglish = "com.apple.voice.compact.en-US.Samantha"  // 美式英语（女声）
    case ukEnglish = "com.apple.voice.compact.en-GB.Daniel"     // 英式英语（男声）
    case auEnglish = "com.apple.voice.compact.en-AU.Karen"      // 澳式英语（女声）
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .usEnglish: return "美式英语（女声）"
        case .ukEnglish: return "英式英语（男声）"
        case .auEnglish: return "澳式英语（女声）"
        }
    }
    
    var identifier: String {
        return self.rawValue
    }
    
    var languageCode: String {
        switch self {
        case .usEnglish: return "en-US"
        case .ukEnglish: return "en-GB"
        case .auEnglish: return "en-AU"
        }
    }
}

// MARK: - TTS服务
@MainActor
class TTSService: NSObject, ObservableObject {
    static let shared = TTSService()
    
    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()
    @Published var isPlaying = false
    @Published var config = TTSConfig()
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        loadConfig()
    }
    
    /// 朗读文本
    func speak(_ text: String) {
        // 如果正在播放，先停止
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        activateAudioSessionIfNeeded()
        
        let utterance = AVSpeechUtterance(string: text)
        
        // 设置语音 - 尝试多种方式
        var voiceToUse: AVSpeechSynthesisVoice?
        
        // 方式1: 尝试使用完整标识符
        voiceToUse = AVSpeechSynthesisVoice(identifier: config.voice.identifier)
        
        // 方式2: 如果失败，尝试使用语言代码
        if voiceToUse == nil {
            voiceToUse = AVSpeechSynthesisVoice(language: config.voice.languageCode)
        }
        
        // 方式3: 如果还是失败，使用默认英语语音
        if voiceToUse == nil {
            voiceToUse = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        utterance.voice = voiceToUse
        
        // 设置参数
        utterance.rate = config.rate
        utterance.pitchMultiplier = config.pitch
        utterance.volume = config.volume
        
        // 调试信息
        print("🔊 TTS Config:")
        print("  Voice: \(config.voice.displayName)")
        print("  Identifier: \(config.voice.identifier)")
        print("  Language: \(config.voice.languageCode)")
        print("  Selected Voice: \(voiceToUse?.name ?? "nil")")
        print("  Rate: \(config.rate), Pitch: \(config.pitch), Volume: \(config.volume)")
        
        // 开始播放
        synthesizer.speak(utterance)
        isPlaying = true
    }
    
    /// 停止播放
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        deactivateAudioSession()
    }
    
    /// 暂停播放
    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }
    
    /// 继续播放
    func resume() {
        synthesizer.continueSpeaking()
    }
    
    /// 更新配置
    func updateConfig(_ newConfig: TTSConfig) {
        config = newConfig
        saveConfig()
    }
    
    /// 保存配置
    private func saveConfig() {
        UserDefaults.standard.set(config.voice.rawValue, forKey: "tts_voice")
        UserDefaults.standard.set(config.rate, forKey: "tts_rate")
        UserDefaults.standard.set(config.pitch, forKey: "tts_pitch")
        UserDefaults.standard.set(config.volume, forKey: "tts_volume")
    }
    
    /// 加载配置
    private func loadConfig() {
        if let voiceRaw = UserDefaults.standard.string(forKey: "tts_voice"),
           let voice = TTSVoice(rawValue: voiceRaw) {
            config.voice = voice
        }
        
        let rate = UserDefaults.standard.float(forKey: "tts_rate")
        if rate > 0 {
            config.rate = rate
        }
        
        let pitch = UserDefaults.standard.float(forKey: "tts_pitch")
        if pitch > 0 {
            config.pitch = pitch
        }
        
        let volume = UserDefaults.standard.float(forKey: "tts_volume")
        if volume > 0 {
            config.volume = volume
        }
    }
    
    /// 获取可用的语音列表
    func getAvailableVoices() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().filter { voice in
            voice.language.hasPrefix("en")
        }
    }
    
    private func activateAudioSessionIfNeeded() {
        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("TTSService audio session activation failed: \(error)")
        }
    }
    
    private func deactivateAudioSession() {
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("TTSService audio session deactivation failed: \(error)")
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension TTSService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlaying = true
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlaying = false
            self.deactivateAudioSession()
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlaying = false
            self.deactivateAudioSession()
        }
    }
}
