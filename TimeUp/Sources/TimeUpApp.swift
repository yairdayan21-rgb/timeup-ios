import SwiftUI
import BackgroundTasks

@main
struct TimeUpApp: App {

    @StateObject private var store =
        TimeUpStore.shared

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

    // MARK: - Background Task Registration

    private func registerBackgroundTasks() {

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier:
                screenTimeSyncTaskIdentifier,
            using: nil
        ) { task in

            guard let refreshTask =
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

    // MARK: - Background Scheduling

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

        // This is the earliest time at which
        // iOS may run the task.
        //
        // iOS decides the actual execution time.
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

    // MARK: - Background Execution

    private func handleBackgroundScreenTimeSync(
        task: BGAppRefreshTask
    ) {

        // Schedule the next opportunity immediately.
        // The system still decides when it actually runs.
        scheduleBackgroundScreenTimeSync()

        let syncTask =
            Task {

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

    // MARK: - Screen Time → Supabase

    @MainActor
    private func syncScreenTimeNow() async {

        let dataStore =
            SupabaseDataStore.shared

        // Background launch may happen before
        // the Supabase account has been loaded.
        if dataStore.currentUser == nil {

            await dataStore
                .loadCurrentAccount()
        }

        guard let group =
            dataStore.activeMemberGroup
        else {
            return
        }

        // Load today's target/result first so
        // the Screen Time result is written with
        // the correct target information.
        await dataStore.loadDailyProgress(
            groupID: group.id
        )

        await dataStore
            .syncReportedScreenTime()
    }
}

private struct RootView: View {

    @EnvironmentObject private var store:
        TimeUpStore

    var body: some View {

        NavigationStack {

            if let member =
                store.currentMember {

                AppLockView(
                    member: member
                )

            } else {

                LoginView()
            }
        }
    }
}
