import SwiftUI

@main
struct TimeUpApp: App {

    @StateObject private var store = TimeUpStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}

private struct RootView: View {

    @EnvironmentObject private var store: TimeUpStore

    var body: some View {
        NavigationStack {

            if let member = store.currentMember {

                AppLockView(member: member)

            } else {

                LoginView()
            }
        }
    }
}
