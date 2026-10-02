import SwiftUI

struct JoinGroupView: View {

    @StateObject private var store = TimeUpStore.shared

    let authProvider: TimeUpAuthProvider?
    let externalUserID: String?

    @State private var groupCode = ""
    @State private var displayName = ""
    @State private var destination: Destination?
    @State private var errorMessage: String?

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

    private enum Destination: Hashable {
        case admin
        case member(UUID)
    }

    private var isReadyToJoin: Bool {
        groupCode.count == 4 &&
        !displayName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
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
                .onSubmit {
                    focusedField = .groupCode
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
                        groupCode = normalized
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

                Button("המשך") {
                    join()
                }
                .accessibilityIdentifier(
                    "join-button"
                )
                .fontWeight(.semibold)
                .frame(
                    maxWidth: .infinity
                )
                .frame(height: 52)
                .buttonStyle(
                    .borderedProminent
                )
                .disabled(!isReadyToJoin)

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
            item: $destination
        ) { destination in

            switch destination {

            case .admin:

                AdminHomeView()
                    .navigationBarBackButtonHidden(
                        true
                    )

            case .member(let memberID):

                if let member =
                    store.members.first(
                        where: {
                            $0.id == memberID
                        }
                    )
                {

                    MemberHomeView(
                        member: member
                    )
                    .navigationBarBackButtonHidden(
                        true
                    )

                } else {

                    ContentUnavailableView(
                        "לא ניתן לפתוח את החבר",
                        systemImage:
                            "person.crop.circle.badge.exclamationmark"
                    )
                }
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

        guard !name.isEmpty else {

            errorMessage =
                "יש להזין שם כדי להמשיך."

            return
        }

        guard code.count == 4 else {

            errorMessage =
                "יש להזין קוד קבוצה בן 4 ספרות."

            return
        }

        // MARK: Existing authenticated account

        if
            let authProvider,
            let externalUserID,
            let existingMember =
                store.member(
                    authProvider:
                        authProvider,
                    externalUserID:
                        externalUserID
                )
        {

            store.setCurrentMember(
                existingMember
            )

            errorMessage = nil

            switch existingMember.role {

            case .admin:
                destination = .admin

            case .member:
                destination =
                    .member(
                        existingMember.id
                    )
            }

            return
        }

        // MARK: Admin shortcut

        if code == "0000" {

            errorMessage = nil
            destination = .admin
            return
        }

        // MARK: Group

        guard let group =
            store.group(
                forCode: code
            )
        else {

            errorMessage =
                "לא נמצאה קבוצה עם הקוד הזה."

            return
        }

        guard !store.hasMember(
            named: name,
            in: group.id
        )
        else {

            errorMessage =
                "השם הזה כבר קיים בקבוצה."

            return
        }

        // MARK: Create member

        let member =
            TimeUpMember(
                groupID: group.id,
                displayName: name,
                authProvider:
                    authProvider,
                externalUserID:
                    externalUserID
            )

        store.addMember(member)

        store.setCurrentMember(
            member
        )

        errorMessage = nil

        destination =
            .member(
                member.id
            )
    }
}
