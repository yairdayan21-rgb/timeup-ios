import SwiftUI

struct AdminGroupDetailView: View {

    let group: TimeUpRemoteGroup

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
                                .foregroundStyle(
                                    .secondary
                                )
                        }

                        Spacer()

                        Image(
                            systemName:
                                "person.3.fill"
                        )
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
                            systemImage:
                                "target"
                        )

                        Spacer()

                        Label(
                            "\(group.currentStreak)",
                            systemImage:
                                "flame.fill"
                        )
                    }
                    .font(.subheadline)

                    if group.goalMethod != "manual" {

                        Text(
                            "מסלול של \(group.successDays ?? 7) ימי הצלחה"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }
                .padding()
                .background(
                    .thinMaterial
                )
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
                            .font(
                                .title3.bold()
                            )

                        Spacer()

                        Text(
                            "\(dataStore.groupMembers.count) חברים"
                        )
                        .font(.subheadline)
                        .foregroundStyle(
                            .secondary
                        )
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
                        .padding(
                            .vertical,
                            30
                        )

                    } else if dataStore.groupMembers.isEmpty {

                        ContentUnavailableView(
                            "אין חברים בקבוצה",
                            systemImage:
                                "person.3",
                            description:
                                Text(
                                    "כאשר משתמשים יצטרפו לקבוצה הם יופיעו כאן."
                                )
                        )
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(
                            .vertical,
                            20
                        )

                    } else {

                        ForEach(
                            dataStore.groupMembers
                        ) { member in

                            memberCard(
                                member
                            )
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
                        .fontWeight(
                            .semibold
                        )

                        Text(error)
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )

                        Button(
                            "נסה שוב"
                        ) {

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
                    .background(
                        .thinMaterial
                    )
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
        .navigationBarTitleDisplayMode(
            .inline
        )
        .refreshable {

            await loadGroup()
        }
        .task {

            await loadGroup()
        }
    }

    // MARK: - Member Card

    private func memberCard(
        _ member: TimeUpRemoteUser
    ) -> some View {

        HStack(
            spacing: 14
        ) {

            ZStack {

                Circle()
                    .fill(
                        .thinMaterial
                    )
                    .frame(
                        width: 46,
                        height: 46
                    )

                Image(
                    systemName:
                        "person.fill"
                )
                .foregroundStyle(
                    .secondary
                )
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(
                    member.displayName
                )
                .fontWeight(
                    .semibold
                )

                if member.role == "admin" {

                    Text("מנהל")
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                } else {

                    Text("חבר קבוצה")
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                }
            }

            Spacer()

            Image(
                systemName:
                    "chevron.left"
            )
            .font(.caption)
            .foregroundStyle(
                .tertiary
            )
        }
        .padding()
        .background(
            .thinMaterial
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
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

            return "יעד אישי לכל משתמש"

        default:

            return "יעד קבוצה"
        }
    }
}
