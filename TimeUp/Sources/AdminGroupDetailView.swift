import SwiftUI

struct AdminHomeView: View {

    @State private var showCreateGroup = false

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {

                    // MARK: - Header

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text("TimeUp")
                            .font(
                                .system(
                                    size: 34,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )

                        Text("ניהול הקבוצות שלך")
                            .foregroundStyle(
                                .secondary
                            )
                    }

                    // MARK: - Create Group

                    Button {

                        showCreateGroup = true

                    } label: {

                        HStack {

                            Image(
                                systemName:
                                    "plus.circle.fill"
                            )
                            .font(.title2)

                            Text(
                                "יצירת קבוצה חדשה"
                            )
                            .fontWeight(
                                .semibold
                            )

                            Spacer()

                            Image(
                                systemName:
                                    "chevron.left"
                            )
                            .foregroundStyle(
                                .secondary
                            )
                        }
                        .padding()
                        .frame(
                            maxWidth: .infinity
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
                    .buttonStyle(.plain)

                    // MARK: - Groups

                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {

                        Text("הקבוצות שלי")
                            .font(
                                .title3.bold()
                            )

                        if dataStore.isLoading &&
                            dataStore.groups.isEmpty {

                            HStack {

                                Spacer()

                                ProgressView(
                                    "טוען קבוצות..."
                                )

                                Spacer()
                            }
                            .padding(
                                .vertical,
                                40
                            )

                        } else if dataStore.groups.isEmpty {

                            ContentUnavailableView(
                                "עדיין אין קבוצות",
                                systemImage:
                                    "person.3",
                                description:
                                    Text(
                                        "צור את הקבוצה הראשונה שלך כדי להתחיל."
                                    )
                            )
                            .frame(
                                maxWidth: .infinity
                            )
                            .padding(
                                .vertical,
                                30
                            )

                        } else {

                            ForEach(
                                dataStore.groups
                            ) { group in

                                NavigationLink {

                                    AdminGroupDetailView(
                                        group: group
                                    )

                                } label: {

                                    groupCard(
                                        group: group
                                    )
                                }
                                .buttonStyle(
                                    .plain
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
                                "לא ניתן לטעון את הנתונים",
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

                                    await dataStore
                                        .loadCurrentAccount()
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
            .refreshable {

                await dataStore
                    .loadCurrentAccount()
            }
            .toolbar {

                ToolbarItem(
                    placement:
                        .topBarTrailing
                ) {

                    Button {

                        Task {

                            await dataStore
                                .loadCurrentAccount()
                        }

                    } label: {

                        Image(
                            systemName:
                                "arrow.clockwise"
                        )
                    }
                }
            }
            .navigationDestination(
                isPresented:
                    $showCreateGroup
            ) {

                CreateGroupView()
            }
            .task {

                await dataStore
                    .loadCurrentAccount()
            }
        }
    }

    // MARK: - Group Card

    private func groupCard(
        group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(group.name)
                        .font(.headline)

                    Text("קוד קבוצה")
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
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

            Text(group.code)
                .font(
                    .system(
                        size: 28,
                        weight: .bold,
                        design: .monospaced
                    )
                )
                .tracking(4)

            Divider()

            HStack(
                spacing: 12
            ) {

                Label(
                    goalDescription(
                        group
                    ),
                    systemImage:
                        "target"
                )

                Spacer()

                Label(
                    "\(group.currentStreak)",
                    systemImage:
                        "flame.fill"
                )
                .foregroundStyle(
                    .secondary
                )

                if group.goalMethod !=
                    "manual" {

                    Text(
                        "\(group.successDays ?? 7) ימים"
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
            .font(.subheadline)
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
    }

    // MARK: - Goal Description

    private func goalDescription(
        _ group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> String {

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
