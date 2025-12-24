//
//  SpeakButton.swift
//  WordLearningApp
//
//  发音按钮组件 - 可复用
//

import SwiftUI

struct SpeakButton: View {
    let text: String
    let size: ButtonSize
    
    @StateObject private var ttsService = TTSService.shared
    
    enum ButtonSize {
        case small
        case medium
        case large
        
        var iconSize: Font {
            switch self {
            case .small: return .caption
            case .medium: return .body
            case .large: return .title3
            }
        }
        
        var frameSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 32
            case .large: return 40
            }
        }
    }
    
    init(text: String, size: ButtonSize = .medium) {
        self.text = text
        self.size = size
    }
    
    var body: some View {
        Button(action: {
            ttsService.speak(text)
        }) {
            ZStack {
                Circle()
                    .fill(ttsService.isPlaying ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                    .frame(width: size.frameSize, height: size.frameSize)
                
                Image(systemName: ttsService.isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                    .font(size.iconSize)
                    .foregroundColor(ttsService.isPlaying ? .green : .blue)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
struct SpeakButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SpeakButton(text: "Hello", size: .small)
            SpeakButton(text: "Hello", size: .medium)
            SpeakButton(text: "Hello", size: .large)
        }
        .padding()
    }
}
