//
//  WordData.swift
//  WordLearningApp
//
//  单词数据模型
//

import Foundation

// MARK: - WordData
struct WordData: Codable, Identifiable {
    let id = UUID()
    let word: String
    let phonetic: String?
    let partOfSpeech: String?
    let chineseDefinition: String?
    let meanings: [Meaning]
    let phrases: [Phrase]
    let examples: [Example]
    let confusingWords: [ConfusingWord]?
    let memoryTips: [MemoryTip]?
    let wordFormsWithLabels: [WordFormLabel]?
    let wordForms: [String]?  // 兼容旧格式
    let etymology: String?
    let etymologyDetails: String?
    let examType: String?
    let updatedAt: String?
    let category: [String]?  // 分类标签
    
    enum CodingKeys: String, CodingKey {
        case word, phonetic, partOfSpeech, chineseDefinition
        case meanings, phrases, examples
        case confusingWords, memoryTips, wordFormsWithLabels, wordForms
        case etymology, etymologyDetails, examType, category
        case updatedAt = "updated_at"
    }

    init(
        word: String,
        phonetic: String? = nil,
        partOfSpeech: String? = nil,
        chineseDefinition: String? = nil,
        meanings: [Meaning] = [],
        phrases: [Phrase] = [],
        examples: [Example] = [],
        confusingWords: [ConfusingWord]? = nil,
        memoryTips: [MemoryTip]? = nil,
        wordFormsWithLabels: [WordFormLabel]? = nil,
        wordForms: [String]? = nil,
        etymology: String? = nil,
        etymologyDetails: String? = nil,
        examType: String? = nil,
        updatedAt: String? = nil,
        category: [String]? = nil
    ) {
        self.word = word
        self.phonetic = phonetic
        self.partOfSpeech = partOfSpeech
        self.chineseDefinition = chineseDefinition
        self.meanings = meanings
        self.phrases = phrases
        self.examples = examples
        self.confusingWords = confusingWords
        self.memoryTips = memoryTips
        self.wordFormsWithLabels = wordFormsWithLabels
        self.wordForms = wordForms
        self.etymology = etymology
        self.etymologyDetails = etymologyDetails
        self.examType = examType
        self.updatedAt = updatedAt
        self.category = category
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let word = try c.decode(String.self, forKey: .word)
        let phonetic = try c.decodeIfPresent(String.self, forKey: .phonetic)
        let partOfSpeech = try c.decodeIfPresent(String.self, forKey: .partOfSpeech)
        let chineseDefinition = try c.decodeIfPresent(String.self, forKey: .chineseDefinition)
        let meanings = try c.decodeIfPresent([Meaning].self, forKey: .meanings) ?? []
        let phrases = try c.decodeIfPresent([Phrase].self, forKey: .phrases) ?? []
        let examples = try c.decodeIfPresent([Example].self, forKey: .examples) ?? []
        let confusingWords = try c.decodeIfPresent([ConfusingWord].self, forKey: .confusingWords)
        let memoryTips = try c.decodeIfPresent([MemoryTip].self, forKey: .memoryTips)
        let wordFormsWithLabels = try c.decodeIfPresent([WordFormLabel].self, forKey: .wordFormsWithLabels)
        let wordForms = try c.decodeIfPresent([String].self, forKey: .wordForms)
        let etymology = try c.decodeIfPresent(String.self, forKey: .etymology)
        let etymologyDetails = try c.decodeIfPresent(String.self, forKey: .etymologyDetails)
        let examType = try c.decodeIfPresent(String.self, forKey: .examType)
        let updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
        let category = try c.decodeIfPresent([String].self, forKey: .category)

        self.init(
            word: word,
            phonetic: phonetic,
            partOfSpeech: partOfSpeech,
            chineseDefinition: chineseDefinition,
            meanings: meanings,
            phrases: phrases,
            examples: examples,
            confusingWords: confusingWords,
            memoryTips: memoryTips,
            wordFormsWithLabels: wordFormsWithLabels,
            wordForms: wordForms,
            etymology: etymology,
            etymologyDetails: etymologyDetails,
            examType: examType,
            updatedAt: updatedAt,
            category: category
        )
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(word, forKey: .word)
        try c.encodeIfPresent(phonetic, forKey: .phonetic)
        try c.encodeIfPresent(partOfSpeech, forKey: .partOfSpeech)
        try c.encodeIfPresent(chineseDefinition, forKey: .chineseDefinition)
        try c.encode(meanings, forKey: .meanings)
        try c.encode(phrases, forKey: .phrases)
        try c.encode(examples, forKey: .examples)
        try c.encodeIfPresent(confusingWords, forKey: .confusingWords)
        try c.encodeIfPresent(memoryTips, forKey: .memoryTips)
        try c.encodeIfPresent(wordFormsWithLabels, forKey: .wordFormsWithLabels)
        try c.encodeIfPresent(wordForms, forKey: .wordForms)
        try c.encodeIfPresent(etymology, forKey: .etymology)
        try c.encodeIfPresent(etymologyDetails, forKey: .etymologyDetails)
        try c.encodeIfPresent(examType, forKey: .examType)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try c.encodeIfPresent(category, forKey: .category)
    }
}

// MARK: - Meaning
struct Meaning: Codable, Identifiable {
    let id = UUID()
    let partOfSpeech: String
    let definition: String
    let example: String?
    let chineseDefinition: String?

    enum CodingKeys: String, CodingKey {
        case partOfSpeech, definition, example, chineseDefinition
    }
}

// MARK: - Phrase
struct Phrase: Codable, Identifiable {
    let id = UUID()
    let phrase: String
    let meaning: String

    enum CodingKeys: String, CodingKey {
        case phrase, meaning
    }
}

// MARK: - Example
struct Example: Codable, Identifiable {
    let id = UUID()
    let sentence: String
    let translation: String?

    enum CodingKeys: String, CodingKey {
        case sentence, translation
    }
}

// MARK: - ConfusingWord
struct ConfusingWord: Codable, Identifiable {
    let id = UUID()
    let words: [String]
    let diff: String
    let example: String?
    let memory: String?

    enum CodingKeys: String, CodingKey {
        case words, diff, example, memory
    }
}

// MARK: - MemoryTip
struct MemoryTip: Codable, Identifiable {
    let id = UUID()
    let type: String
    let content: String
    let association: String?

    enum CodingKeys: String, CodingKey {
        case type, content, association
    }
}

// MARK: - WordFormLabel
struct WordFormLabel: Codable, Identifiable {
    let id = UUID()
    let label: String
    let word: String
    let type: String  // "grammatical" or "semantic"
    
    var isGrammatical: Bool {
        type == "grammatical"
    }
    
    var isSemantic: Bool {
        type == "semantic"
    }

    enum CodingKeys: String, CodingKey {
        case label, word, type
    }
}

// MARK: - ExamType
enum ExamType: String, CaseIterable, Codable {
    case cet4 = "CET4"
    case cet6 = "CET6"
    case postgraduate = "考研英语"
    case toefl = "托福"
    case ielts = "雅思"
    
    var displayName: String {
        return rawValue
    }
}


