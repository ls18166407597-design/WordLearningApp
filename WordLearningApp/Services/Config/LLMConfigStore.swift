import Foundation

struct LLMConfig: Codable, Equatable {
    var apiKey: String
    var baseURL: String
    var model: String
    var expandedMode: Bool

    static let `default` = LLMConfig(
        apiKey: "",
        baseURL: "https://dashscope.aliyuncs.com/compatible-mode/v1",
        model: "qwen-plus",
        expandedMode: false
    )

    init(apiKey: String, baseURL: String, model: String, expandedMode: Bool = false) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
        self.expandedMode = expandedMode
    }

    enum CodingKeys: String, CodingKey {
        case apiKey, baseURL, model, expandedMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let apiKey = try container.decode(String.self, forKey: .apiKey)
        let baseURL = try container.decode(String.self, forKey: .baseURL)
        let model = try container.decode(String.self, forKey: .model)
        let expandedMode = try container.decodeIfPresent(Bool.self, forKey: .expandedMode) ?? false
        self.init(apiKey: apiKey, baseURL: baseURL, model: model, expandedMode: expandedMode)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(apiKey, forKey: .apiKey)
        try container.encode(baseURL, forKey: .baseURL)
        try container.encode(model, forKey: .model)
        try container.encode(expandedMode, forKey: .expandedMode)
    }
}

final class LLMConfigStore: ObservableObject {
    static let shared = LLMConfigStore()

    @Published private(set) var config: LLMConfig

    private let defaults = UserDefaults.standard
    private let key = "llm_config"

    private init() {
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(LLMConfig.self, from: data) {
            self.config = decoded
        } else {
            self.config = .default
        }
    }

    func update(_ config: LLMConfig) {
        self.config = config
        if let data = try? JSONEncoder().encode(config) {
            defaults.set(data, forKey: key)
        }
    }
}
