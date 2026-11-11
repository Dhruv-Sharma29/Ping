import SwiftUI

struct RootView: View {
    @State private var tab = RootTab.repos

    var body: some View {
        TabView(selection: $tab) {
            Tab("Repos", systemImage: "dot.radiowaves.left.and.right", value: .repos) {
                RepoListView()
            }
            Tab("Issues", systemImage: "list.bullet.rectangle", value: .issues) {
                AllIssuesView()
            }
            Tab("Explore", systemImage: "globe", value: .explore) {
                ExploreView()
            }
            Tab("For You", systemImage: "sparkles", value: .forYou) {
                ForYouView()
            }
        }
    }
}
