import SwiftUI

struct AdminMemberDetailView: View {

    let group: SupabaseDataStore.TimeUpRemoteGroup
    let member: SupabaseDataStore.TimeUpRemoteUser

    @StateObject private var dataStore = SupabaseDataStore.shared

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Member Header

                VStack(spacing: 12) {

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.secondary)

                    Text(member.displayName ?? "משתמש")
                        .font(.title2.bold())

                    Text(
                        member.role == "admin"
                        ? "מנהל"
                        : "חבר קבוצה"
                    )
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)

                // MARK: - Group

                VStack(alignment: .leading, spacing: 12) {

                    Text("קבוצה")
                        .font(.headline)

                    HStack {

                        Text(group.name)

                        Spacer()

                        Text(group.code)
                            .font(
                                .system(
                                    .body,
                                    design: .monospaced
                                )
                            )
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )

                // MARK: - Goal

                VStack(alignment: .leading, spacing: 12) {

                    Text("שיטת היעד")
                        .font(.headline)

                    HStack {

                        Image(systemName: "target")

                        Text(goalDescription)

                        Spacer()
                    }

                    if group.goalMethod == "manual" {

                        Divider()

                        Label(
                            "בקבוצה זו מוגדר יעד אישי לכל משתמש",
                            systemImage:
                                "person.crop.circle.badge.checkmark"
                        )
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )

                // MARK: - Screen Time

                VStack(alignment: .leading, spacing: 12) {

                    Text("זמן מסך")
                        .font(.headline)

                    Label(
                        "נתוני המשתמש נטענים מ־Supabase",
                        systemImage: "iphone"
                    )
                    .foregroundStyle(.secondary)

                    Text(
                        "בשלב הבא נחבר כאן את זמן המסך, היעד היומי, סטטוס ההצלחה וההיסטוריה של המשתמש."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )
            }
            .padding(20)
        }
        .navigationTitle(
            member.displayName ?? "משתמש"
        )
        .navigationBarTitleDisplayMode(.inline)
        .task {

            await dataStore.loadDailyProgress(
                groupID: group.id
            )
        }
    }

    private var goalDescription: String {

        switch group.goalMethod {

        case "personal_percentage":

            return
                "\(group.reductionPercent ?? 0)% פחות מהיום הקודם"

        case "group_average_percentage":

            return
                "\(group.reductionPercent ?? 0)% פחות מהממוצע הקבוצתי"

        case "manual":

            return "יעד אישי"

        default:

            return "יעד קבוצה"
        }
    }
}
