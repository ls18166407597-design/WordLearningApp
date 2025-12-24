import Foundation

@MainActor
final class WordDetailViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var wordData: WordData?
    @Published var isCacheHit: Bool = false

    private let api = APIService.shared
    private let storage = LocalStorage.shared

    func load(word: String, examType: ExamType, forceRefresh: Bool = false) async {
        let w = word.trimmingCharacters(in: .whitespacesAndNewlines)
        if !forceRefresh, let cached = api.getCachedWord(w) {
            wordData = cached
            errorMessage = ""
            isCacheHit = true
            return
        }

        isLoading = true
        isCacheHit = false
        errorMessage = ""
        do {
            let data = try await api.generateWordData(word: w, examType: examType)
            wordData = data
            storage.addToHistory(w)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func toggleFavorite(word: String) {
        let w = word.lowercased()
        if storage.isFavorite(w) {
            storage.removeFavorite(w)
        } else {
            storage.addFavorite(w)
        }
        objectWillChange.send()
    }

    func isFavorite(word: String) -> Bool {
        storage.isFavorite(word)
    }
}
