import SwiftUI

struct AdminGroupDetailView: View {

    let group: SupabaseDataStore.TimeUpRemoteGroup

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @State private var isRefreshing = false

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 24
            ) {

                // MARK: - Group Header

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    HStack {

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {

                            Text(group.name)
                                .font(
                                    .system(
                                        size: 30,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )

                            Text("קוד קבוצה")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "person.3.fill")
                            .font(.title2)
                    }

                    Text(group.code)
                        .font(
                            .system(
                                size: 30,
                                weight: .bold,
                                design: .monospaced
                            )
                        )
                        .tracking(5)

                    Divider()

                    HStack {

                        Label(
                            goalDescription,
                            systemImage: "target"
                        )

                        Spacer()

                        Label(
                            "\(group.currentStreak)",
                            systemImage: "flame.fill"
                        )
                    }
                    .font(.subheadline)

                    Text(
                        "מסלול של \(group.successDays ?? 7) ימי הצלחה"
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

                // MARK: - Settings

                NavigationLink {

                    GroupSettingsView(
                        group: group
                    )

                } label: {

                    HStack(spacing: 14) {

                        ZStack {

                            Circle()
                                .fill(.thinMaterial)
                                .frame(
                                    width: 46,
                                    height: 46
                                )

                            Image(
                                systemName: "gearshape.fill"
                            )
                            .foregroundStyle(.secondary)
                        }

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {

                            Text("הגדרות קבוצה")
                                .fontWeight(.semibold)

                            Text(
                                "שם, שיטת יעד, אחוז הפחתה ומספר ימי הצלחה"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(
                            systemName: "chevron.left"
                        )
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                    )
                }
                .buttonStyle(.plain)

                // MARK: - Today's Group Status

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    HStack {

                        Text("מצב הקבוצה היום")
                            .font(.title3.bold())

                        Spacer()

                        if isRefreshing {

                            ProgressView()
                        }
                    }

                    if let todayGroupResult {

                        HStack(spacing: 12) {

                            Image(
                                systemName:
                                    todayGroupResult.succeeded
                                    ? "checkmark.circle.fill"
                                    : "xmark.circle.fill"
                            )
                            .font(.title2)

                            VStack(
                                alignment: .leading,
                                spacing: 3
                            ) {

                                Text(
                                    todayGroupResult.succeeded
                                    ? "הקבוצה עמדה ביעד"
                                    : "הקבוצה לא עמדה ביעד"
                                )
                                .fontWeight(.semibold)

                                Text(
                                    "\(todayGroupResult.completedMemberCount) מתוך \(todayGroupResult.memberCount) חברים השלימו"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(
                                alignment: .trailing,
                                spacing: 3
                            ) {

                                Text(
                                    "רצף \(todayGroupResult.streakAfterDay)"
                                )
                                .fontWeight(.semibold)

                                if let average =
                                    todayGroupResult.averageUsageMinutes {

                                    Text(
                                        "ממוצע \(formatMinutes(average))"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }

                    } else {

                        HStack(spacing: 12) {

                            Image(
                                systemName: "clock.fill"
                            )
                            .font(.title2)

                            VStack(
                                alignment: .leading,
                                spacing: 3
                            ) {

                                Text("היום עדיין לא הסתיים")
                                    .fontWeight(.semibold)

                                Text(
                                    "התוצאה הקבוצתית תיסגר אוטומטית לאחר שכל נתוני היום יתקבלו."
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )

                // MARK: - Members

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    HStack {

                        Text("חברי הקבוצה")
                            .font(.title3.bold())

                        Spacer()

                        Text(
                            "\(dataStore.groupMembers.count) חברים"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    if isRefreshing &&
                        dataStore.groupMembers.isEmpty {

                        HStack {

                            Spacer()

                            ProgressView(
                                "טוען חברים..."
                            )

                            Spacer()
                        }
                        .padding(.vertical, 30)

                    } else if dataStore.groupMembers.isEmpty {

                        ContentUnavailableView(
                            "אין חברים בקבוצה",
                            systemImage: "person.3",
                            description: Text(
                                "כאשר משתמשים יצטרפו לקבוצה הם יופיעו כאן."
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)

                    } else {

                        ForEach(
                            dataStore.groupMembers
                        ) { member in

                            NavigationLink {

                                AdminMemberDetailView(
                                    group: group,
                                    member: member
                                )

                            } label: {

                                memberCard(member)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // MARK: - Error

                if let error =
                    dataStore.lastError {

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Label(
                            "לא ניתן לטעון את נתוני הקבוצה",
                            systemImage:
                                "exclamationmark.triangle"
                        )
                        .fontWeight(.semibold)

                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("נסה שוב") {

                            Task {

                                await loadGroup()
                            }
                        }
                    }
                    .padding()
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .background(.thinMaterial)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )
                }
            }
            .padding(20)
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {

            await loadGroup()
        }
        .task {

            await loadGroup()
        }
    }

    // MARK: - Member Card

    private func memberCard(
        _ member: SupabaseDataStore.TimeUpRemoteUser
    ) -> some View {

        HStack(spacing: 14) {

            ZStack {

                Circle()
                    .fill(.thinMaterial)
                    .frame(
                        width: 46,
                        height: 46
                    )

                Image(
                    systemName: "person.fill"
                )
                .foregroundStyle(.secondary)
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(
                    member.displayName ?? "משתמש"
                )
                .fontWeight(.semibold)

                if member.role == "admin" {

                    Text("מנהל")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                } else {

                    Text("חבר קבוצה")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let result =
                todayResult(
                    for: member.id
                ) {

                VStack(
                    alignment: .trailing,
                    spacing: 3
                ) {

                    Text(
                        formatMinutes(
                            result.usageMinutes
                        )
                    )
                    .font(.subheadline.bold())

                    if result.isLearningDay {

                        Text("יום למידה")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                    } else if result.achieved == true {

                        Label(
                            "עמד ביעד",
                            systemImage: "checkmark.circle.fill"
                        )
                        .font(.caption)

                    } else if result.achieved == false {

                        Label(
                            "חריגה",
                            systemImage: "xmark.circle.fill"
                        )
                        .font(.caption)

                    } else {

                        Text("ממתין")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

            } else {

                Text("ממתין לנתונים")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Image(
                systemName: "chevron.left"
            )
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    // MARK: - Today's Data

    private var todayGroupResult:
        SupabaseDataStore.TimeUpRemoteGroupDailyResult? {

        dataStore.groupDailyResults.first {
            $0.groupID == group.id &&
            $0.resultDate == todayDateKey
        }
    }

    private func todayResult(
        for userID: UUID
    ) -> SupabaseDataStore.TimeUpRemoteDailyResult? {

        dataStore.dailyResults.first {
            $0.groupID == group.id &&
            $0.userID == userID &&
            $0.resultDate == todayDateKey
        }
    }

    // MARK: - Load

    @MainActor
    private func loadGroup() async {

        isRefreshing = true

        await dataStore.loadGroupMembers(
            groupID: group.id
        )

        await dataStore.loadDailyProgress(
            groupID: group.id
        )

        isRefreshing = false
    }

    // MARK: - Date

    private var todayDateKey: String {

        let formatter =
            DateFormatter()

        formatter.calendar =
            Calendar(
                identifier: .gregorian
            )

        formatter.locale =
            Locale(
                identifier:
                    "en_US_POSIX"
            )

        formatter.timeZone =
            TimeZone(
                identifier:
                    group.timezone
            ) ??
            TimeZone(
                identifier:
                    "Asia/Jerusalem"
            ) ??
            .current

        formatter.dateFormat =
            "yyyy-MM-dd"

        return formatter.string(
            from: Date()
        )
    }

    // MARK: - Formatting

    private func formatMinutes(
        _ minutes: Int
    ) -> String {

        let hours =
            minutes / 60

        let remainingMinutes =
            minutes % 60

        if hours == 0 {

            return
                "\(remainingMinutes) דק׳"
        }

        if remainingMinutes == 0 {

            return
                "\(hours) שע׳"
        }

        return
            "\(hours) שע׳ \(remainingMinutes) דק׳"
    }

    // MARK: - Goal

    private var goalDescription: String {

        switch group.goalMethod {

        case "personal_percentage":

            return
                "\(group.reductionPercent ?? 0)% פחות מהיום הקודם"

        case "group_average_percentage":

            return
                "\(group.reductionPercent ?? 0)% פחות מהממוצע הקבוצתי"

        case "manual":

            return
                "יעד אישי לכל משתמש"

        default:

            return "יעד קבוצה"
        }
    }
}