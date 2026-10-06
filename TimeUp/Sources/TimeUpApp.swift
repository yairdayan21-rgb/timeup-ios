import SwiftUI
import BackgroundTasks

@main
struct TimeUpApp: App {

    @StateObject private var store =
        TimeUpStore.shared

    @StateObject private var localization =
        TimeUpLocalization.shared

    private let screenTimeSyncTaskIdentifier =
        "com.timeup.app.screen-time-sync"

    init() {
        registerBackgroundTasks()
        scheduleBackgroundScreenTimeSync()
    }

    var body: some Scene {

        WindowGroup {

            RootView()
                .environmentObject(store)

                // MARK: - Global Localization

                .environment(
                    \.locale,
                    localization.language.locale
                )

                .environment(
                    \.layoutDirection,
                    localization.language.layoutDirection
                )

                .onAppear {

                    scheduleBackgroundScreenTimeSync()

                    Task {
                        await syncScreenTimeNow()
                    }
                }

                .onReceive(
                    NotificationCenter.default.publisher(
                        for:
                            UIApplication
                                .didBecomeActiveNotification
                    )
                ) { _ in

                    scheduleBackgroundScreenTimeSync()

                    Task {
                        await syncScreenTimeNow()
                    }
                }
        }
    }


    // MARK: - Background Tasks

    private func registerBackgroundTasks() {

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier:
                screenTimeSyncTaskIdentifier,
            using: nil
        ) { task in

            guard
                let refreshTask =
                    task as? BGAppRefreshTask
            else {

                task.setTaskCompleted(
                    success: false
                )

                return
            }

            handleBackgroundScreenTimeSync(
                task: refreshTask
            )
        }
    }


    private func scheduleBackgroundScreenTimeSync() {

        BGTaskScheduler.shared.cancel(
            taskRequestWithIdentifier:
                screenTimeSyncTaskIdentifier
        )

        let request =
            BGAppRefreshTaskRequest(
                identifier:
                    screenTimeSyncTaskIdentifier
            )

        request.earliestBeginDate =
            Date(
                timeIntervalSinceNow:
                    10 * 60
            )

        do {

            try BGTaskScheduler.shared.submit(
                request
            )

        } catch {

            print(
                "TimeUp background sync scheduling failed:",
                error.localizedDescription
            )
        }
    }


    private func handleBackgroundScreenTimeSync(
        task: BGAppRefreshTask
    ) {

        scheduleBackgroundScreenTimeSync()

        let syncTask = Task {

            await syncScreenTimeNow()

            if !Task.isCancelled {

                task.setTaskCompleted(
                    success: true
                )
            }
        }

        task.expirationHandler = {

            syncTask.cancel()

            task.setTaskCompleted(
                success: false
            )
        }
    }


    // MARK: - Screen Time Sync

    @MainActor
    private func syncScreenTimeNow() async {

        let dataStore =
            SupabaseDataStore.shared

        if dataStore.currentUser == nil {

            await dataStore.loadCurrentAccount()
        }

        guard
            let group =
                dataStore.activeMemberGroup
        else {
            return
        }

        await dataStore.loadDailyProgress(
            groupID: group.id
        )

        await dataStore.syncReportedScreenTime()
    }
}


// MARK: - Root View

private struct RootView: View {

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @State private var didLoadAccount = false


    var body: some View {

        NavigationStack {

            Group {

                if !didLoadAccount {

                    ProgressView(
                        loadingText
                    )

                } else if
                    dataStore.currentUser == nil {

                    LoginView()

                } else if
                    dataStore.isAdmin {

                    AdminTabView()

                } else if
                    dataStore.hasActiveGroup {

                    MemberTabView()

                } else {

                    JoinGroupView()
                }
            }
        }

        .task {

            guard !didLoadAccount else {
                return
            }

            await dataStore.loadCurrentAccount()

            didLoadAccount = true
        }
    }


    // MARK: - Localized Root Text

    private var loadingText: String {

        switch localization.language {

        case .hebrew:
            return "טוען את TimeUp..."

        case .english:
            return "Loading TimeUp..."

        case .arabic:
            return "جارٍ تحميل TimeUp..."
        }
    }
}