//
//  HomeViewModel.swift
//  WordLearningApp
//
//  主页面视图模型
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var recentHistory: [String] = []
    @Published var autocomplete: [String] = []
    
    private let storage = LocalStorage.shared
    private let api = APIService.shared
    
    func loadHistory() {
        recentHistory = storage.getHistory()
    }

    func updateAutocomplete(prefix: String) {
        autocomplete = api.localAutocomplete(prefix: prefix)
    }
}


