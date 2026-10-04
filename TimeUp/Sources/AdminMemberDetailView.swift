import SwiftUI

struct AdminMemberDetailView: View {

    let group: SupabaseDataStore.TimeUpRemoteGroup
    let member: SupabaseDataStore.TimeUpRemoteUser

    @StateObject private var dataStore = SupabaseDataStore.shared

    @State private var isLoading = false

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

                // MARK: - Today's Status

                VStack(alignment: .leading, spacing: 16) {

                    HStack {

                        Text("היום")
                            .font(.headline)

                        Spacer()

                        if isLoading {

                            ProgressView()
                        }
                    }

                    if let result = todayResult {

                        HStack(spacing: 12) {

                            statusCard(
                                title: "זמן מסך",
                                value: formatMinutes(
                                    result.usageMinutes
                                ),
                                icon: "iphone"
                            )

                            statusCard(
                                title: "יעד",
                                value: targetText(
                                    result
                                ),
                                icon: "target"
                            )
                        }

                        Divider()

                        if result.isLearningDay {

                            Label(
                                "יום למידה",
                                systemImage:
                                    "brain.head.profile"
                            )
                            .font(.headline)

                            Text(
                                "היום משמש למדידת זמן המסך לצורך קביעת היעד הראשון. יום זה אינו נספר ברצף."
                            )
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        } else {

                            HStack {

                                Image(
                                    systemName:
                                        result.achieved == true
                                        ? "checkmark.circle.fill"
                                        : "xmark.circle.fill"
                                )
                                .font(.title2)

                                VStack(
                                    alignment: .leading,
                                    spacing: 2
                                ) {

                                    Text(
                                        result.achieved == true
                                        ? "עמד ביעד"
                                        : "עדיין לא עמד ביעד"
                                    )
                                    .fontWeight(.semibold)

                                    if let target =
                                        result.targetMinutes {

                                        Text(
                                            statusDescription(
                                                usage:
                                                    result.usageMinutes,
                                                target:
                                                    target
                                            )
                                        )
                                        .font(.caption)
                                        .foregroundStyle(
                                            .secondary
                                        )
                                    }
                                }

                                Spacer()
                            }
                        }

                    } else if let target = todayTarget {

                        HStack(spacing: 12) {

                            statusCard(
                                title: "זמן מסך",
                                value: "טרם התקבל",
                                icon: "iphone"
                            )

                            statusCard(
                                title: "יעד",
                                value: formatMinutes(
                                    target.targetMinutes
                                ),
                                icon: "target"
                            )
                        }

                        Divider()

                        Label(
                            "ממתין לנתוני זמן מסך",
                            systemImage:
                                "clock.arrow.circlepath"
                        )
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    } else {

                        ContentUnavailableView(
                            "אין נתונים להיום",
                            systemImage: "iphone.slash",
                            description: Text(
                                "עדיין לא התקבלו נתוני זמן מסך או יעד עבור המשתמש."
                            )
                        )
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )

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
                        .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )

                // MARK: - Manual Goal

                if group.goalMethod == "manual" {

                    VStack(
                        alignment: .leading,
                        spacing: 10
                    ) {

                        Label(
                            "יעד אישי",
                            systemImage:
                                "person.crop.circle.badge.checkmark"
                        )
                        .font(.headline)

                        if let target = todayTarget {

                            Text(
                                "היעד הנוכחי: \(formatMinutes(target.targetMinutes))"
                            )

                        } else if let result = todayResult,
                                  let target =
                                    result.targetMinutes {

                            Text(
                                "היעד הנוכחי: \(formatMinutes(target))"
                            )

                        } else {

                            Text(
                                "עדיין לא הוגדר יעד למשתמש."
                            )
                            .foregroundStyle(.secondary)
                        }

                        Text(
                            "בשלב הבא נחבר כאן את האפשרות של המנהל לקבוע ולשנות את היעד האישי."
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

                // MARK: - Error

                if let error = dataStore.lastError {

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Label(
                            "לא ניתן לטעון את הנתונים",
                            systemImage:
                                "exclamationmark.triangle"
                        )
                        .fontWeight(.semibold)

                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("נסה שוב") {

                            Task {
                                await loadData()
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
        .navigationTitle(
            member.displayName ?? "משתמש"
        )
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {

            await loadData()
        }
        .task {

            await loadData()
        }
    }

    // MARK: - Today's Data

    private var todayResult:
        SupabaseDataStore.TimeUpRemoteDailyResult? {

        dataStore.dailyResults.first {
            $0.userID == member.id
        }
    }

    private var todayTarget:
        SupabaseDataStore.TimeUpRemoteDailyTarget? {

        dataStore.dailyTargets.first {
            $0.userID == member.id
        }
    }

    // MARK: - Status Card

    private func statusCard(
        title: String,
        value: String,
        icon: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Label(
                title,
                systemImage: icon
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.bold())
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            .ultraThinMaterial
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14
            )
        )
    }

    // MARK: - Load

    @MainActor
    private func loadData() async {

        isLoading = true

        await dataStore.loadDailyProgress(
            groupID: group.id
        )

        isLoading = false
    }

    // MARK: - Formatting

    private func formatMinutes(
        _ minutes: Int
    ) -> String {

        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours == 0 {
            return "\(remainingMinutes) דק׳"
        }

        if remainingMinutes == 0 {
            return "\(hours) שע׳"
        }

        return "\(hours) שע׳ \(remainingMinutes) דק׳"
    }

    private func targetText(
        _ result:
            SupabaseDataStore.TimeUpRemoteDailyResult
    ) -> String {

        guard let target =
                result.targetMinutes else {

            return "ללא יעד"
        }

        return formatMinutes(target)
    }

    private func statusDescription(
        usage: Int,
        target: Int
    ) -> String {

        let difference =
            abs(target - usage)

        if usage <= target {

            return
                "נותרו \(formatMinutes(difference)) עד היעד"
        }

        return
            "חריגה של \(formatMinutes(difference))"
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

            return "יעד אישי"

        default:

            return "יעד קבוצה"
        }
    }
}