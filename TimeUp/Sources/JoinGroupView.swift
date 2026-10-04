import SwiftUI

struct JoinGroupView: View {

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    let authProvider: TimeUpAuthProvider?
    let externalUserID: String?

    @State private var groupCode = ""
    @State private var displayName = ""
    @State private var isJoining = false
    @State private var errorMessage: String?
    @State private var joinedGroupID: UUID?

    @FocusState private var focusedField: Field?

    init(
        authProvider: TimeUpAuthProvider? = nil,
        externalUserID: String? = nil
    ) {
        self.authProvider = authProvider
        self.externalUserID = externalUserID
    }

    private enum Field {
        case displayName
        case groupCode
    }

    private var isReadyToJoin: Bool {

        let name =
            displayName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return
            groupCode.count == 4 &&
            !name.isEmpty &&
            !isJoining
    }

    var body: some View {

        ScrollView {

            VStack(spacing: 24) {

                Image(
                    systemName: "person.3.fill"
                )
                .font(.system(size: 54))
                .padding(.top, 32)

                VStack(spacing: 8) {

                    Text("הצטרפות ל-TimeUp")
                        .font(
                            .system(
                                size: 30,
                                weight: .bold,
                                design: .rounded
                            )
                        )

                    Text(
                        "הזן את הקוד שקיבלת כדי להמשיך"
                    )
                    .foregroundStyle(.secondary)
                }

                TextField(
                    "השם שלך",
                    text: $displayName
                )
                .accessibilityIdentifier(
                    "display-name-field"
                )
                .textInputAutocapitalization(
                    .words
                )
                .multilineTextAlignment(
                    .center
                )
                .textFieldStyle(
                    .roundedBorder
                )
                .focused(
                    $focusedField,
                    equals: .displayName
                )
                .submitLabel(.next)
                .disabled(isJoining)
                .onSubmit {

                    focusedField =
                        .groupCode
                }
                .onChange(
                    of: displayName
                ) { _, _ in

                    errorMessage = nil
                }

                TextField(
                    "קוד קבוצה",
                    text: $groupCode
                )
                .accessibilityIdentifier(
                    "group-code-field"
                )
                .keyboardType(.numberPad)
                .multilineTextAlignment(
                    .center
                )
                .font(
                    .system(
                        size: 28,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .textFieldStyle(
                    .roundedBorder
                )
                .focused(
                    $focusedField,
                    equals: .groupCode
                )
                .disabled(isJoining)
                .onChange(
                    of: groupCode
                ) { _, newValue in

                    let normalized =
                        String(
                            newValue
                                .filter {
                                    $0.isNumber
                                }
                                .prefix(4)
                        )

                    if groupCode != normalized {

                        groupCode =
                            normalized
                    }

                    errorMessage = nil
                }

                if let errorMessage {

                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(
                            .center
                        )
                        .accessibilityIdentifier(
                            "join-error"
                        )
                }

                Button {

                    join()

                } label: {

                    HStack(spacing: 10) {

                        if isJoining {

                            ProgressView()
                                .tint(.white)
                        }

                        Text(
                            isJoining
                            ? "מצטרף..."
                            : "המשך"
                        )
                        .fontWeight(.semibold)
                    }
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(height: 52)
                }
                .accessibilityIdentifier(
                    "join-button"
                )
                .buttonStyle(
                    .borderedProminent
                )
                .disabled(
                    !isReadyToJoin
                )

                Text(
                    "קוד הקבוצה מתקבל ממנהל הקבוצה"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(
            .interactively
        )
        .navigationTitle("")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .toolbar {

            ToolbarItemGroup(
                placement: .keyboard
            ) {

                Spacer()

                Button("סיום") {

                    focusedField = nil
                }
            }
        }
        .navigationDestination(
            item: $joinedGroupID
        ) { groupID in

            SupabaseJoinedGroupView(
                groupID: groupID,
                displayName:
                    displayName
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
            )
            .navigationBarBackButtonHidden(
                true
            )
        }
        .task {

            if dataStore.currentUser == nil {

                await dataStore
                    .loadCurrentAccount()
            }
        }
    }

    // MARK: - Join

    private func join() {

        let name =
            displayName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let code =
            groupCode
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        focusedField = nil
        errorMessage = nil

        guard !name.isEmpty else {

            errorMessage =
                "יש להזין שם כדי להמשיך."

            return
        }

        guard
            code.count == 4,
            code.allSatisfy({
                $0.isNumber
            })
        else {

            errorMessage =
                "יש להזין קוד קבוצה בן 4 ספרות."

            return
        }

        isJoining = true

        Task {

            do {

                if dataStore.currentUser == nil {

                    await dataStore
                        .loadCurrentAccount()
                }

                guard
                    dataStore.currentUser != nil
                else {

                    throw JoinGroupError
                        .userNotAvailable
                }

                try await dataStore
                    .updateDisplayName(name)

                let groupID =
                    try await dataStore
                        .joinGroup(
                            code: code
                        )

                await MainActor.run {

                    isJoining = false
                    errorMessage = nil
                    joinedGroupID =
                        groupID
                }

            } catch {

                await MainActor.run {

                    isJoining = false
                    errorMessage =
                        message(
                            for: error
                        )
                }
            }
        }
    }

    // MARK: - Errors

    private func message(
        for error: Error
    ) -> String {

        let raw =
            (
                error.localizedDescription +
                " " +
                String(
                    describing: error
                )
            )
            .uppercased()

        if raw.contains(
            "GROUP_NOT_FOUND"
        ) {

            return
                "לא נמצאה קבוצה עם הקוד הזה."
        }

        if raw.contains(
            "INVALID_GROUP_CODE"
        ) {

            return
                "קוד הקבוצה אינו תקין."
        }

        if raw.contains(
            "ALREADY_IN_GROUP"
        ) {

            return
                "החשבון כבר משויך לקבוצה."
        }

        if raw.contains(
            "ADMIN_CANNOT_JOIN_AS_MEMBER"
        ) {

            return
                "חשבון מנהל אינו יכול להצטרף כחבר קבוצה."
        }

        if raw.contains(
            "NOT_AUTHENTICATED"
        ) {

            return
                "החיבור לחשבון הסתיים. יש להתחבר מחדש."
        }

        if raw.contains(
            "TIMEUP_USER_NOT_FOUND"
        ) {

            return
                "לא נמצא חשבון TimeUp מחובר."
        }

        if raw.contains(
            "USER_NOT_AVAILABLE"
        ) {

            return
                "לא ניתן לטעון את החשבון. יש להתחבר מחדש."
        }

        return
            "לא ניתן היה להצטרף לקבוצה כרגע. נסה שוב."
    }
}

// MARK: - Joined Group

private struct SupabaseJoinedGroupView: View {

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    let groupID: UUID
    let displayName: String

    var body: some View {

        Group {

            if dataStore.isLoading {

                VStack(spacing: 16) {

                    ProgressView()

                    Text(
                        "טוען את הקבוצה..."
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

            } else if let group =
                dataStore.groups.first(
                    where: {
                        $0.id == groupID
                    }
                )
            {

                VStack(spacing: 24) {

                    Image(
                        systemName:
                            "checkmark.circle.fill"
                    )
                    .font(
                        .system(size: 64)
                    )
                    .foregroundStyle(
                        .green
                    )

                    Text(
                        "הצטרפת בהצלחה"
                    )
                    .font(
                        .largeTitle.bold()
                    )

                    Text(group.name)
                        .font(.title2)
                        .fontWeight(
                            .semibold
                        )

                    Text(
                        "שלום \(displayName)"
                    )
                    .foregroundStyle(
                        .secondary
                    )

                    Text(
                        "הקבוצה מחוברת כעת לחשבון שלך ב-TimeUp."
                    )
                    .multilineTextAlignment(
                        .center
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
                .padding(24)

            } else {

                ContentUnavailableView(
                    "לא ניתן לטעון את הקבוצה",
                    systemImage:
                        "person.3.sequence.fill",
                    description:
                        Text(
                            "ההצטרפות נשמרה, אך פרטי הקבוצה עדיין לא נטענו."
                        )
                )
            }
        }
        .task {

            await dataStore
                .loadCurrentAccount()
        }
    }
}

// MARK: - Join Error

private enum JoinGroupError:
    LocalizedError {

    case userNotAvailable

    var errorDescription: String? {

        switch self {

        case .userNotAvailable:

            return
                "USER_NOT_AVAILABLE"
        }
    }
}
