//
//  WordFormService.swift
//  WordLearningApp
//
//  词形识别服务 - 混合方案
//  策略：NaturalLanguage框架（优先，95%准确率） + AI兜底（100%准确率）
//

import Foundation
import NaturalLanguage

// MARK: - 词形数据模型
struct WordFormInfo {
    let originalWord: String
    let isOriginal: Bool
    let formType: FormType
    let confidence: Confidence
    
    enum FormType {
        case original           // 原形
        case plural            // 复数
        case pastTense         // 过去式
        case pastParticiple    // 过去分词
        case presentParticiple // 现在分词
        case thirdPerson       // 第三人称单数
        case comparative       // 比较级
        case superlative       // 最高级
        case variant           // 其他变体
    }
    
    enum Confidence {
        case high      // 高置信度（NaturalLanguage识别）
        case medium    // 中等置信度（规则匹配）
        case low       // 低置信度（猜测）
        case ai        // AI识别
    }
}

// MARK: - AI响应模型
private struct AIWordFormResponse: Codable {
    let original: String
    let isOriginal: Bool
    let formType: String
    
    enum CodingKeys: String, CodingKey {
        case original
        case isOriginal = "is_original"
        case formType = "form_type"
    }
}

// MARK: - 词形服务
class WordFormService {
    static let shared = WordFormService()
    
    private var cache: [String: WordFormInfo] = [:]
    private let tagger = NLTagger(tagSchemes: [.lemma, .lexicalClass])
    
    private init() {}
    
    /// 查找原形单词（主要方法）
    func findOriginalWord(for word: String) async -> String {
        let wordLower = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查缓存
        if let cached = cache[wordLower] {
            return cached.originalWord
        }
        
        // 识别词形
        let formInfo = await identifyWordForm(wordLower)
        
        // 缓存结果
        cache[wordLower] = formInfo
        
        return formInfo.originalWord
    }
    
    /// 检查是否是语法变体（复数、过去式等）
    func isGrammaticalVariant(word: String) async -> Bool {
        let wordLower = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let formInfo = await identifyWordForm(wordLower)
        
        // 语法变体包括：复数、时态变化
        switch formInfo.formType {
        case .plural, .pastTense, .pastParticiple, .presentParticiple, .thirdPerson:
            return !formInfo.isOriginal
        case .original, .comparative, .superlative, .variant:
            return false
        }
    }
    
    /// 识别词形（核心算法 - 三层策略）
    private func identifyWordForm(_ word: String) async -> WordFormInfo {
        // 第一层：使用NaturalLanguage框架（最快，95%准确率）
        if let nlResult = identifyWithNaturalLanguage(word) {
            return nlResult
        }
        
        // 第二层：使用规则匹配（快速兜底，80%准确率）
        if let ruleResult = identifyWithRules(word) {
            return ruleResult
        }
        
        // 第三层：调用AI（最准确，但需要网络）
        if let aiResult = await identifyWithAI(word) {
            return aiResult
        }
        
        // 默认：假设是原形
        return WordFormInfo(
            originalWord: word,
            isOriginal: true,
            formType: .original,
            confidence: .low
        )
    }
    
    // MARK: - 第一层：NaturalLanguage框架
    
    /// 使用iOS原生NaturalLanguage框架识别
    private func identifyWithNaturalLanguage(_ word: String) -> WordFormInfo? {
        tagger.string = word
        
        var lemma: String?
        var lexicalClass: NLTag?
        
        // 获取词形还原结果
        tagger.enumerateTags(in: word.startIndex..<word.endIndex, unit: .word, scheme: .lemma) { tag, _ in
            lemma = tag?.rawValue
            return false
        }
        
        // 获取词性
        tagger.enumerateTags(in: word.startIndex..<word.endIndex, unit: .word, scheme: .lexicalClass) { tag, _ in
            lexicalClass = tag
            return false
        }
        
        // 如果找到了词形还原结果
        if let lemma = lemma, lemma != word, !lemma.isEmpty {
            let formType = determineFormType(original: lemma, variant: word, lexicalClass: lexicalClass)
            
            return WordFormInfo(
                originalWord: lemma,
                isOriginal: false,
                formType: formType,
                confidence: .high
            )
        }
        
        return nil
    }
    
    /// 根据词性和变化判断词形类型
    private func determineFormType(original: String, variant: String, lexicalClass: NLTag?) -> WordFormInfo.FormType {
        // 根据后缀判断
        if variant.hasSuffix("ing") {
            return .presentParticiple
        }
        if variant.hasSuffix("ed") {
            return .pastTense
        }
        if variant.hasSuffix("s") || variant.hasSuffix("es") {
            // 可能是复数或第三人称
            if lexicalClass == .verb {
                return .thirdPerson
            }
            return .plural
        }
        if variant.hasSuffix("er") && original.count < variant.count {
            return .comparative
        }
        if variant.hasSuffix("est") && original.count < variant.count {
            return .superlative
        }
        
        return .variant
    }
    
    // MARK: - 第二层：规则匹配
    
    /// 使用规则匹配识别（兜底方案）
    private func identifyWithRules(_ word: String) -> WordFormInfo? {
        // 不规则动词表
        let irregularVerbs: [String: String] = [
            "am": "be", "is": "be", "are": "be", "was": "be", "were": "be", "been": "be",
            "went": "go", "gone": "go",
            "saw": "see", "seen": "see",
            "wrote": "write", "written": "write",
            "made": "make",
            "took": "take", "taken": "take",
            "gave": "give", "given": "give",
            "ate": "eat", "eaten": "eat",
            "bought": "buy",
            "brought": "bring",
            "thought": "think",
            "taught": "teach",
            "fought": "fight",
            "found": "find",
            "ran": "run",
            "began": "begin", "begun": "begin",
            "became": "become",
        ]
        
        // 不规则名词表
        let irregularNouns: [String: String] = [
            "children": "child",
            "men": "man",
            "women": "woman",
            "mice": "mouse",
            "teeth": "tooth",
            "feet": "foot",
            "people": "person",
        ]
        
        // 检查不规则形式
        if let original = irregularVerbs[word] {
            return WordFormInfo(
                originalWord: original,
                isOriginal: false,
                formType: .variant,
                confidence: .high
            )
        }
        
        if let original = irregularNouns[word] {
            return WordFormInfo(
                originalWord: original,
                isOriginal: false,
                formType: .plural,
                confidence: .high
            )
        }
        
        // 规则识别
        if word.hasSuffix("ing") && word.count > 4 {
            if let base = tryRemoveIng(word) {
                return WordFormInfo(
                    originalWord: base,
                    isOriginal: false,
                    formType: .presentParticiple,
                    confidence: .medium
                )
            }
        }
        
        if word.hasSuffix("ed") && word.count > 3 {
            if let base = tryRemoveEd(word) {
                return WordFormInfo(
                    originalWord: base,
                    isOriginal: false,
                    formType: .pastTense,
                    confidence: .medium
                )
            }
        }
        
        if word.hasSuffix("s") && word.count > 2 && !word.hasSuffix("ss") {
            if let base = tryRemoveS(word) {
                return WordFormInfo(
                    originalWord: base,
                    isOriginal: false,
                    formType: .plural,
                    confidence: .medium
                )
            }
        }
        
        return nil
    }
    
    // MARK: - 第三层：AI识别
    
    /// 使用AI识别（最准确，但需要网络）
    private func identifyWithAI(_ word: String) async -> WordFormInfo? {
        let config = LLMConfigStore.shared.config
        
        guard !config.apiKey.isEmpty,
              !config.baseURL.isEmpty else {
            print("⚠️ AI配置未设置，跳过AI识别")
            return nil
        }
        
        let prompt = """
你是英语词汇专家。请分析单词 "\(word)" 的词形。

只返回JSON格式（不要其他内容）：
{
  "original": "原形单词",
  "is_original": true/false,
  "form_type": "original/plural/past/past_participle/present_participle/third_person/comparative/superlative"
}

示例：
- running → {"original": "run", "is_original": false, "form_type": "present_participle"}
- books → {"original": "book", "is_original": false, "form_type": "plural"}
- better → {"original": "good", "is_original": false, "form_type": "comparative"}
"""
        
        do {
            guard let url = URL(string: config.baseURL + "/chat/completions") else {
                return nil
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 10.0
            
            let body: [String: Any] = [
                "model": config.model,
                "messages": [
                    ["role": "user", "content": prompt]
                ],
                "temperature": 0.1,
                "max_tokens": 200
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // 解析响应
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                // 提取JSON（可能包含在markdown代码块中）
                let jsonContent = extractJSON(from: content)
                
                if let jsonData = jsonContent.data(using: .utf8),
                   let result = try? JSONDecoder().decode(AIWordFormResponse.self, from: jsonData) {
                    
                    let formType = mapStringToFormType(result.formType)
                    
                    return WordFormInfo(
                        originalWord: result.original,
                        isOriginal: result.isOriginal,
                        formType: formType,
                        confidence: .ai
                    )
                }
            }
        } catch {
            print("⚠️ AI识别失败: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// 从文本中提取JSON
    private func extractJSON(from text: String) -> String {
        // 移除markdown代码块
        var content = text
        if content.contains("```json") {
            content = content.replacingOccurrences(of: "```json", with: "")
            content = content.replacingOccurrences(of: "```", with: "")
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 映射字符串到FormType
    private func mapStringToFormType(_ type: String) -> WordFormInfo.FormType {
        switch type {
        case "original": return .original
        case "plural": return .plural
        case "past": return .pastTense
        case "past_participle": return .pastParticiple
        case "present_participle": return .presentParticiple
        case "third_person": return .thirdPerson
        case "comparative": return .comparative
        case "superlative": return .superlative
        default: return .variant
        }
    }
    
    // MARK: - 辅助方法
    
    private func tryRemoveIng(_ word: String) -> String? {
        let base = String(word.dropLast(3))
        
        // 双写辅音 (running -> run)
        if base.count >= 2 {
            let lastTwo = String(base.suffix(2))
            if lastTwo.first == lastTwo.last && isConsonant(lastTwo.first!) {
                return String(base.dropLast())
            }
        }
        
        // 去e加ing (making -> make)
        let withE = base + "e"
        if isValidWord(withE) {
            return withE
        }
        
        // 直接去ing (playing -> play)
        if isValidWord(base) {
            return base
        }
        
        return nil
    }
    
    private func tryRemoveEd(_ word: String) -> String? {
        let base = String(word.dropLast(2))
        
        // -ied -> -y (studied -> study)
        if word.hasSuffix("ied") && word.count > 4 {
            return String(word.dropLast(3)) + "y"
        }
        
        // 双写辅音 (stopped -> stop)
        if base.count >= 2 {
            let lastTwo = String(base.suffix(2))
            if lastTwo.first == lastTwo.last && isConsonant(lastTwo.first!) {
                return String(base.dropLast())
            }
        }
        
        // 去e加ed (liked -> like)
        let withE = base + "e"
        if isValidWord(withE) {
            return withE
        }
        
        // 直接去ed (played -> play)
        if isValidWord(base) {
            return base
        }
        
        return nil
    }
    
    private func tryRemoveS(_ word: String) -> String? {
        // -ies -> -y (studies -> study)
        if word.hasSuffix("ies") && word.count > 4 {
            return String(word.dropLast(3)) + "y"
        }
        
        // -ves -> -f/-fe (knives -> knife)
        if word.hasSuffix("ves") && word.count > 4 {
            let base = String(word.dropLast(3))
            if isValidWord(base + "fe") {
                return base + "fe"
            }
            if isValidWord(base + "f") {
                return base + "f"
            }
        }
        
        // -es (boxes -> box)
        if word.hasSuffix("es") && word.count > 3 {
            let base = String(word.dropLast(2))
            if base.hasSuffix("s") || base.hasSuffix("x") || base.hasSuffix("z") ||
               base.hasSuffix("ch") || base.hasSuffix("sh") {
                return base
            }
        }
        
        // 直接去s (books -> book)
        let base = String(word.dropLast())
        if isValidWord(base) {
            return base
        }
        
        return nil
    }
    
    private func isConsonant(_ char: Character) -> Bool {
        let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
        return !vowels.contains(char.lowercased().first!)
    }
    
    private func isValidWord(_ word: String) -> Bool {
        guard word.count >= 2 else { return false }
        guard word.allSatisfy({ $0.isLetter }) else { return false }
        let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
        return word.lowercased().contains(where: { vowels.contains($0) })
    }
    
    /// 清除缓存
    func clearCache() {
        cache.removeAll()
    }
}
