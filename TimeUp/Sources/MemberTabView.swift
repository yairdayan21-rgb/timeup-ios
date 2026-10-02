import SwiftUI

struct MemberTabView: View {

    let member: TimeUpMember

    @StateObject private var store =
        TimeUpStore.shared

    @State private var selectedTab:
        MemberTab = .dashboard

    @State private var showProfile = false

    private enum MemberTab: Hashable {
        case ranking
        case ai
        case group
        case dashboard
    }

    var body: some View {

        TabView(selection: $selectedTab) {

            // MARK: - Ranking

            NavigationStack {

                placeholderView(
                    title: "דירוג",
                    icon: "trophy.fill",
                    message:
                        "כאן יוצג הדירוג הגלובלי של הקבוצות הפעילות."
                )
                .toolbar {
                    profileToolbar
                }
            }
            .tabItem {
                Label(
                    "דירוג",
                    systemImage: "trophy"
                )
            }
            .tag(MemberTab.ranking)

            // MARK: - AI

            NavigationStack {

                placeholderView(
                    title: "AI",
                    icon: "sparkles",
                    message:
                        "כאן יהיה הצ׳אט האישי שלך עם TimeUp AI."
                )
                .toolbar {
                    profileToolbar
                }
            }
            .tabItem {
                Label(
                    "AI",
                    systemImage: "sparkles"
                )
            }
            .tag(MemberTab.ai)

            // MARK: - Group

            NavigationStack {

                MemberGroupView(
                    member: currentMember
                )
                .toolbar {
                    profileToolbar
                }
            }
            .tabItem {
                Label(
                    "הקבוצה",
                    systemImage: "person.3"
                )
            }
            .tag(MemberTab.group)

            // MARK: - Dashboard

            NavigationStack {

                MemberHomeView(
                    member: currentMember
                )
                .toolbar {
                    profileToolbar
                }
            }
            .tabItem {
                Label(
                    "דשבורד",
                    systemImage:
                        "square.grid.2x2.fill"
                )
            }
            .tag(MemberTab.dashboard)
        }
        .sheet(
            isPresented: $showProfile
        ) {

            NavigationStack {

                MemberProfileView(
                    member: currentMember
                )
            }
        }
    }

    // MARK: - Current Member

    private var currentMember: TimeUpMember {

        store.member(
            id: member.id
        ) ?? member
    }

    // MARK: - Profile Button

    @ToolbarContentBuilder
    private var profileToolbar:
        some ToolbarContent
    {

        ToolbarItem(
            placement: .topBarTrailing
        ) {

            Button {

                showProfile = true

            } label: {

                ZStack {

                    Circle()
                        .fill(
                            Color.secondary
                                .opacity(0.15)
                        )
                        .frame(
                            width: 36,
                            height: 36
                        )

                    Image(
                        systemName:
                            "person.crop.circle.fill"
                    )
                    .font(.system(size: 28))
                }
            }
            .accessibilityLabel(
                "פרופיל"
            )
        }
    }

    // MARK: - Temporary Screen

    private func placeholderView(
        title: String,
        icon: String,
        message: String
    ) -> some View {

        VStack(spacing: 18) {

            Spacer()

            Image(
                systemName: icon
            )
            .font(
                .system(size: 54)
            )

            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(message)
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .center
                )
                .padding(.horizontal, 32)

            Spacer()
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}


// MARK: - Member Profile

private struct MemberProfileView: View {

    let member: TimeUpMember

    @Environment(\.dismiss)
    private var dismiss

    @StateObject private var store =
        TimeUpStore.shared

    var body: some View {

        List {

            // MARK: Profile

            Section {

                VStack(spacing: 14) {

                    Image(
                        systemName:
                            "person.crop.circle.fill"
                    )
                    .font(
                        .system(size: 82)
                    )
                    .foregroundStyle(
                        .secondary
                    )

                    Text(member.displayName)
                        .font(.title2)
                        .fontWeight(.bold)

                }
                .frame(
                    maxWidth: .infinity
                )
                .padding(.vertical, 16)
            }

            // MARK: Settings

            Section {

                NavigationLink {

                    PersonalSettingsView()

                } label: {

                    Label(
                        "הגדרות",
                        systemImage: "gearshape"
                    )
                }
            }

            // MARK: Logout

            Section {

                Button(
                    role: .destructive
                ) {

                    logout()

                } label: {

                    Label(
                        "יציאה מהחשבון",
                        systemImage:
                            "rectangle.portrait.and.arrow.right"
                    )
                }
            }
        }
        .navigationTitle("פרופיל")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .toolbar {

            ToolbarItem(
                placement: .topBarLeading
            ) {

                Button("סגור") {

                    dismiss()
                }
            }
        }
    }

    private func logout() {

        store.clearCurrentMember()

        dismiss()
    }
}
