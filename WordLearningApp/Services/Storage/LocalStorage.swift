//
//  LocalStorage.swift
//  WordLearningApp
//
//  本地存储服务
//

import Foundation

class LocalStorage {
    static let shared = LocalStorage()
    
    private let favoritesKey = "favorites"
    private let historyKey = "history"
    private let wordsDirectory: URL
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        wordsDirectory = documentsPath.appendingPathComponent("words")
        
        // 创建words目录
        try? FileManager.default.createDirectory(at: wordsDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    
    // MARK: - 收藏管理
    func saveFavorites(_ words: [String]) {
        UserDefaults.standard.set(words, forKey: favoritesKey)
    }
    
    func getFavorites() -> [String] {
        UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
    }
    
    func addFavorite(_ word: String) {
        var favorites = getFavorites()
        if !favorites.contains(word.lowercased()) {
            favorites.append(word.lowercased())
            saveFavorites(favorites)
        }
    }
    
    func removeFavorite(_ word: String) {
        var favorites = getFavorites()
        favorites.removeAll { $0.lowercased() == word.lowercased() }
        saveFavorites(favorites)
    }
    
    func isFavorite(_ word: String) -> Bool {
        getFavorites().contains(word.lowercased())
    }
    
    // MARK: - 历史记录
    func saveHistory(_ words: [String]) {
        UserDefaults.standard.set(words, forKey: historyKey)
    }
    
    func getHistory() -> [String] {
        UserDefaults.standard.stringArray(forKey: historyKey) ?? []
    }
    
    func addToHistory(_ word: String) {
        var history = getHistory()
        // 移除重复项
        history.removeAll { $0.lowercased() == word.lowercased() }
        // 添加到开头
        history.insert(word.lowercased(), at: 0)
        // 限制历史记录数量
        if history.count > 50 {
            history = Array(history.prefix(50))
        }
        saveHistory(history)
    }
    
    // MARK: - 单词数据缓存
    func saveWordData(_ word: String, data: WordData) {
        let fileName = "\(word.lowercased()).json"
        let fileURL = wordsDirectory.appendingPathComponent(fileName)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: fileURL)
        } catch {
            print("保存单词数据失败: \(error)")
        }
    }
    
    func getWordData(_ word: String) -> WordData? {
        let fileName = "\(word.lowercased()).json"
        let fileURL = wordsDirectory.appendingPathComponent(fileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode(WordData.self, from: data)
        } catch {
            print("读取单词数据失败: \(error)")
            return nil
        }
    }
    
    func deleteWordData(_ word: String) {
        let fileName = "\(word.lowercased()).json"
        let fileURL = wordsDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    func deleteAllWordData() {
        getAllWords().forEach { deleteWordData($0) }
    }
    
    func getAllWords() -> [String] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: wordsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return files
            .filter { $0.pathExtension == "json" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }
}


