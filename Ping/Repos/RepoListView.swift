import SwiftData
import SwiftUI
import UserNotifications

struct RepoListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var phase
    @Query(sort: \Repo.name) private var repos: [Repo]
    @State private var notificationsOff = false
    @State private var backgroundOff = false

    var body: some View {
        NavigationStack {
            List {
                if notificationsOff {
                    NotificationsOffSection()
                }
                if backgroundOff {
                    BackgroundOffSection()
                }

                AddRepoSection(onAdd: add)

                if repos.isEmpty {
                    ContentUnavailableView(
                        "No Repos Yet",
                        systemImage: "dot.radiowaves.left.and.right",
                        description: Text("Add a repo and Ping will tell you when someone opens a new issue.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    Section("Watching") {
                        ForEach(repos) { repo in
                            NavigationLink(value: repo.name) {
                                RepoRow(repo: repo)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Ping")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileButton()
                }
            }
            .navigationDestination(for: String.self) { IssueListView(repo: $0) }
            .refreshable { await Checker.run(force: true) }
            .task { await start() }
            .onChange(of: phase) {
                if phase == .active { Task { await becameActive() } }
            }
        }
    }

    private func start() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        await becameActive()
    }

    /// Re-checks on every return to the app; the user may have changed notification settings meanwhile.
    private func becameActive() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsOff = settings.authorizationStatus == .denied
        backgroundOff = UIApplication.shared.backgroundRefreshStatus == .denied
        await Checker.run()
    }

    private func add(_ name: String) {
        guard !repos.contains(where: { $0.name.lowercased() == name.lowercased() }) else { return }
        context.insert(Repo(name: name))
        Task { await Checker.run(force: true) } // seeds lastSeen right away
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(repos[index]) }
    }
}

#Preview {
    RepoListView()
        .modelContainer(for: Repo.self, inMemory: true)
}
