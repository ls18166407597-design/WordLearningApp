//
//  APIService.swift
//  WordLearningApp
//
//  API服务 - 与Flask后端通信
//

import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()

    private let session: URLSession
    private let configStore = LLMConfigStore.shared
    private let storage = LocalStorage.shared

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: configuration)
    }

    func getCachedWord(_ word: String) -> WordData? {
        storage.getWordData(word)
    }

    func localAutocomplete(prefix: String) -> [String] {
        let p = prefix.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !p.isEmpty else { return [] }
        return storage.getAllWords().filter { $0.hasPrefix(p) }.prefix(12).map { $0 }
    }

    func generateWordData(word: String, examType: ExamType) async throws -> WordData {
        let normalized = word.trimmingCharacters(in: .whitespacesAndNewlines)
        if let cached = getCachedWord(normalized) {
            return cached
        }

        let cfg = configStore.config
        let apiKey = cfg.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if apiKey.isEmpty {
            throw APIError.missingConfig
        }

        let endpoint = cfg.baseURL.hasSuffix("/") ? "\(cfg.baseURL)chat/completions" : "\(cfg.baseURL)/chat/completions"
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidEndpoint
        }

        let density = cfg.expandedMode ? GenerationDensity.expanded : .standard
        let posFocus = Self.guessPartOfSpeech(for: normalized).joined(separator: " / ")
        let schemaHint = """
请严格只输出【一个 JSON 对象】，不要用 Markdown，不要用 ```，不要输出任何解释文字。

数据结构（键必须齐全；没有就给 null 或 []）：
{
  "word": string,
  "phonetic": string|null,                // 建议 IPA，若有英美两种可写 "[US] ... | [UK] ..."
  "partOfSpeech": string|null,
  "chineseDefinition": string|null,
  "meanings": [ { "partOfSpeech": string, "definition": string, "example": string|null, "chineseDefinition": string|null } ],
  "phrases": [ { "phrase": string, "meaning": string } ],
  "examples": [ { "sentence": string, "translation": string|null } ],
  "confusingWords": [ { "words": [string], "diff": string, "example": string|null, "memory": string|null } ] | null,
  "memoryTips": [ { "type": string, "content": string, "association": string|null } ] | null,
  "wordFormsWithLabels": [ { "label": string, "word": string, "type": "grammatical" | "semantic" } ] | null,
  "wordForms": [string] | null,
  "etymology": string|null,
  "etymologyDetails": string|null,
  "examType": string|null,
  "updated_at": string|null,              // ISO8601
  "category": [string]|null               // 如 "academic","daily","slang"
}

质量准则（目标词常见词性：\(posFocus)）：
1. meanings 至少 \(density.minMeanings) 条，优先覆盖不同词性/语义；若该词常用含义 ≥3 个，必须全部覆盖并给中文解释或记忆点。
2. examples 至少 \(density.minExamples) 条，其中 ≥1 条结合同步考试/真实情境，并附中文翻译。
3. phrases 至少 \(density.minPhrases) 条，优先常考或高频场景。若词本身为动词/名词，请兼顾固定搭配。
4. confusingWords 若目标词易被混淆，必须列出差异；【重要】必须是真正容易混淆的单词（拼写相似、发音相似、意思相近但有区别），不要填同义词或近义词！例如：affect vs effect（拼写相似但词性不同）、accept vs except（拼写相似但意思不同）。错误示例：like vs such as（这是同义词，不是易混淆）。确无可填 null。
5. memoryTips 提供 \(density.minMemoryTips) 个以上的图像化/构词/谐音等方法；若确实想不到，再返回 null。
6. wordFormsWithLabels 指出动词三态、名词复数、形容词/副词形式或近义词（label 示例：“过去式”“形容词形式”“同义词”）。
7. etymology 用 1 段简洁文本说明来源（参考本地 words 数据风格，如“源自…，经…演变，原指…，后引申为…”），优先写清语言来源/词根/演变路径；若确无资料，填 "暂无" 并说明原因。etymologyDetails 可为 null 或 "暂无"（不要写“补充说明”两段式）。
8. 所有英文文本自然简洁，中文解释准确，不要机翻腔；若信息不足也要说明原因。
\(density.modeNote)

额外要求：
- 任何字符串字段（如 phonetic、partOfSpeech、chineseDefinition、memoryTips.content 等）如果确实缺失，直接填上 "暂无" 并说明原因；不要留空字符串。
- 数组字段若没有内容，返回 null 或 []，并尽量在相关字段的字符串中说明“暂无数据”。
- etymology/etymologyDetails 均使用中文自然表述；不要输出 EN/CN 标签。
- confusingWords 至少提供 1 组比较对象。【重要】必须是真正容易混淆的单词（拼写相似、发音相似、意思相近但有区别的词），不要填同义词或近义词！若确实没有高频混淆词，可填 null。
- confusingWords.diff 必须按照"单词: 说明"的格式，每个单词一行，用换行符(\\n)分隔。例如："like: 作动词时表示喜欢或像\\nalike: 是形容词，表示相似的"。禁止只给某一个词的释义，必须每个词都有说明。

请结合“考试类型：\(examType.rawValue)”的需求来挑选例句、短语和技巧，保证学习者看完即可理解并能立即应用。

示例：
{"word":"example","phonetic":"/ɪɡˈzɑːmpəl/","partOfSpeech":"n.","chineseDefinition":"例子；典型事物","meanings":[{"partOfSpeech":"n.","definition":"a representative instance that illustrates a rule","example":"Teachers often start with an inspiring example to hook the class.","chineseDefinition":"能够说明规则的典型实例"},{"partOfSpeech":"n.","definition":"something worthy of imitation","example":"Her persistence is an example to us all.","chineseDefinition":"值得效法的典范"}],"phrases":[{"phrase":"for example","meaning":"例如；举例来说"},{"phrase":"set an example","meaning":"树立榜样"}],"examples":[{"sentence":"This museum is a fine example of modern architecture.","translation":"这座博物馆是现代建筑的杰出例子。"},{"sentence":"You should, for example, review vocabulary every night before CET-4.","translation":"例如，在四级备考时你应该每晚复习词汇。"}],"confusingWords":[{"words":["example","sample"],"diff":"sample 指“样品”，强调代表整体的一小部分；example 强调用来说明概念。","example":"The sample of fabric felt rough, but the example sentence was smooth.","memory":"S 开头的 sample 像“商品” sample。"}],"memoryTips":[{"type":"构词","content":"ex-（向外）+ ample（丰富）→向外展示的“例子”","association":"想像从箱子里掏出很多例子"}],"wordFormsWithLabels":[{"label":"复数","word":"examples","type":"grammatical"},{"label":"形容词","word":"exemplary","type":"semantic"}],"wordForms":["examples"],"etymology":"源自拉丁语 exemplum，表示“范本、样板”。","etymologyDetails":"暂无","examType":"CET4","updated_at":"2025-01-01T00:00:00Z","category":["academic","daily"]}
"""

        let system = "你是资深英语教研员，需要面向中国学习者生成高质量的单词学习卡片。所有输出必须符合给定 JSON 架构，不要添加任何解释文字。根据词性重点和学习深度要求来安排内容密度。"
        let user = "目标单词：\(normalized)\n考试类型：\(examType.rawValue)\n\n\(schemaHint)"

        let body: [String: Any] = [
            "model": cfg.model,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ],
            "temperature": 0.4,
            "max_tokens": 1200,
            "stream": false
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let raw = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(httpResponse.statusCode, raw)
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        let content = decoded.choices.first?.message.content ?? ""
        let json = Self.extractJSONObject(from: content)
        guard let jsonData = json.data(using: .utf8) else {
            throw APIError.decodingError
        }

        let wordData = try JSONDecoder().decode(WordData.self, from: jsonData)
        storage.saveWordData(normalized, data: wordData)
        return wordData
    }

    private static func extractJSONObject(from content: String) -> String {
        var s = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if s.hasPrefix("```") {
            if let firstNewline = s.firstIndex(of: "\n"),
               let lastFence = s.range(of: "```", options: .backwards)?.lowerBound,
               firstNewline < lastFence {
                s = String(s[s.index(after: firstNewline)..<lastFence]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        if s.hasPrefix("{") && s.hasSuffix("}") {
            return s
        }
        if let start = s.firstIndex(of: "{"), let end = s.lastIndex(of: "}"), start < end {
            return String(s[start...end])
        }
        return s
    }
}

// MARK: - Prompt helpers
extension APIService {
    private enum GenerationDensity {
        case standard
        case expanded

        var minMeanings: Int { self == .expanded ? 4 : 3 }
        var minExamples: Int { self == .expanded ? 3 : 2 }
        var minPhrases: Int { self == .expanded ? 3 : 2 }
        var minMemoryTips: Int { self == .expanded ? 2 : 1 }
        var modeNote: String {
            switch self {
            case .standard:
                return "默认模式：确保覆盖核心信息，使学习者在 2-3 分钟内掌握要点。"
            case .expanded:
                return "【扩展学习模式已开启】请提供更丰富的释义、短语、例句和记忆技巧，以便深入掌握。"
            }
        }
    }

    private static func guessPartOfSpeech(for word: String) -> [String] {
        let w = word.lowercased()
        var tags = Set<String>()

        func add(_ tag: String) { tags.insert(tag) }

        if w.hasSuffix("tion") || w.hasSuffix("ment") || w.hasSuffix("ness") ||
            w.hasSuffix("ity") || w.hasSuffix("ence") || w.hasSuffix("ance") ||
            w.hasSuffix("ship") || w.hasSuffix("ism") || w.hasSuffix("ist") ||
            w.hasSuffix("er") || w.hasSuffix("or") {
            add("noun")
        }
        if w.hasSuffix("ate") || w.hasSuffix("ize") || w.hasSuffix("ise") ||
            w.hasSuffix("fy") || w.hasSuffix("en") || w.hasSuffix("ing") ||
            w.hasSuffix("ed") {
            add("verb")
        }
        if w.hasSuffix("ous") || w.hasSuffix("ive") || w.hasSuffix("able") ||
            w.hasSuffix("ible") || w.hasSuffix("al") || w.hasSuffix("ful") ||
            w.hasSuffix("less") || w.hasSuffix("ish") || w.hasSuffix("ic") ||
            w.hasSuffix("y") {
            add("adjective")
        }
        if w.hasSuffix("ly") {
            add("adverb")
        }

        if tags.isEmpty {
            if w.count <= 4 {
                add("noun")
            } else {
                add("noun")
                add("verb")
            }
        }

        return Array(tags)
    }
}

// MARK: - OpenAI Compatible Response Models
struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }

        let message: Message
    }

    let choices: [Choice]
}

// MARK: - API Error
enum APIError: LocalizedError {
    case invalidResponse
    case httpError(Int, String)
    case decodingError
    case networkError(Error)
    case missingConfig
    case invalidEndpoint
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "无效的服务器响应"
        case .httpError(let code, let body):
            return body.isEmpty ? "HTTP错误: \(code)" : "HTTP错误: \(code)\n\(body)"
        case .decodingError:
            return "数据解析失败"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .missingConfig:
            return "未配置 API Key：请先到设置页填写"
        case .invalidEndpoint:
            return "Base URL 不合法"
        }
    }
}


