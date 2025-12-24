import SwiftUI

enum RootTab: Hashable {
    case learn
    case favorites
    case history
    case settings
}

struct RootTabView: View {
    @State private var selectedTab: RootTab = .learn

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
            .tabItem {
                Label("学习", systemImage: "book")
            }
            .tag(RootTab.learn)

            NavigationStack {
                FavoritesView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("收藏", systemImage: "star")
            }
            .tag(RootTab.favorites)

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("词库", systemImage: "tray.full")
            }
            .tag(RootTab.history)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gear")
            }
            .tag(RootTab.settings)
        }
    }
}
