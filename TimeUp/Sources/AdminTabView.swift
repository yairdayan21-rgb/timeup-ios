import SwiftUI

struct AdminTabView: View {

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    var body: some View {
        TabView {
            AdminHomeView()
                .tabItem {
                    Label(
                        homeText,
                        systemImage: "square.grid.2x2.fill"
                    )
                }

            AdminGroupsView()
                .tabItem {
                    Label(
                        groupsText,
                        systemImage: "person.3.fill"
                    )
                }
        }
    }

    private var homeText: String {
        switch localization.language {
        case .hebrew:
            return "ראשי"
        case .english:
            return "Home"
        case .arabic:
            return "الرئيسية"
        }
    }

    private var groupsText: String {
        switch localization.language {
        case .hebrew:
            return "קבוצות"
        case .english:
            return "Groups"
        case .arabic:
            return "المجموعات"
        }
    }
}

// MARK: - Groups

private struct AdminGroupsView: View {

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                groupsText,
                systemImage: "person.3.fill",
                description: Text(groupsDescription)
            )
            .navigationTitle(groupsText)
        }
    }

    private var groupsText: String {
        switch localization.language {
        case .hebrew:
            return "קבוצות"
        case .english:
            return "Groups"
        case .arabic:
            return "المجموعات"
        }
    }

    private var groupsDescription: String {
        switch localization.language {
        case .hebrew:
            return "כאן יוצגו כל הקבוצות שהמנהל יצר."
        case .english:
            return "All groups created by the admin will appear here."
        case .arabic:
            return "ستظهر هنا جميع المجموعات التي أنشأها المدير."
        }
    }
}