import SwiftUI

struct JoinGroupView: View {

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

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
                .font(
                    .system(size: 54)
                )
                .padding(
                    .top,
                    32
                )

                VStack(spacing: 8) {

                    Text(
                        joinTitle
                    )
                    .font(
                        .system(
                            size: 30,
                            weight: .bold,
                            design: .rounded
                        )
                    )

                    Text(
                        joinSubtitle
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .multilineTextAlignment(
                        .center
                    )
                }

                TextField(
                    namePlaceholder,
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
                .submitLabel(
                    .next
                )
                .disabled(
                    isJoining
                )
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
                    groupCodePlaceholder,
                    text: $groupCode
                )
                .accessibilityIdentifier(
                    "group-code-field"
                )
                .keyboardType(
                    .numberPad
                )
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
                .disabled(
                    isJoining
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

                    if groupCode !=
                        normalized {

                        groupCode =
                            normalized
                    }

                    errorMessage =
                        nil
                }

                if let errorMessage {

                    Text(
                        errorMessage
                    )
                    .font(.footnote)
                    .foregroundStyle(
                        .red
                    )
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

                    HStack(
                        spacing: 10
                    ) {

                        if isJoining {

                            ProgressView()
                                .tint(
                                    .white
                                )
                        }

                        Text(
                            isJoining
                                ? joiningText
                                : continueText
                        )
                        .fontWeight(
                            .semibold
                        )
                    }
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(
                        height: 52
                    )
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
                    groupCodeHelpText
                )
                .font(.footnote)
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .center
                )
                .padding(
                    .top,
                    8
                )
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

                Button(
                    doneText
                ) {

                    focusedField =
                        nil
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
                            in:
                                .whitespacesAndNewlines
                        )
            )
            .navigationBarBackButtonHidden(
                true
            )
        }
        .task {

            if dataStore.currentUser ==
                nil {

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
                    in:
                        .whitespacesAndNewlines
                )

        let code =
            groupCode
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        focusedField = nil
        errorMessage = nil

        guard !name.isEmpty
        else {

            errorMessage =
                missingNameText

            return
        }

        guard
            code.count == 4,
            code.allSatisfy({
                $0.isNumber
            })
        else {

            errorMessage =
                invalidCodeFormatText

            return
        }

        isJoining = true

        Task {

            do {

                if dataStore.currentUser ==
                    nil {

                    await dataStore
                        .loadCurrentAccount()
                }

                guard
                    dataStore.currentUser !=
                        nil
                else {

                    throw JoinGroupError
                        .userNotAvailable
                }

                try await dataStore
                    .updateDisplayName(
                        name
                    )

                let groupID =
                    try await dataStore
                        .joinGroup(
                            code: code
                        )

                await MainActor.run {

                    isJoining =
                        false

                    errorMessage =
                        nil

                    joinedGroupID =
                        groupID
                }

            } catch {

                await MainActor.run {

                    isJoining =
                        false

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
                groupNotFoundText
        }

        if raw.contains(
            "INVALID_GROUP_CODE"
        ) {

            return
                invalidGroupCodeText
        }

        if raw.contains(
            "ALREADY_IN_GROUP"
        ) {

            return
                alreadyInGroupText
        }

        if raw.contains(
            "ADMIN_CANNOT_JOIN_AS_MEMBER"
        ) {

            return
                adminCannotJoinText
        }

        if raw.contains(
            "NOT_AUTHENTICATED"
        ) {

            return
                sessionExpiredText
        }

        if raw.contains(
            "TIMEUP_USER_NOT_FOUND"
        ) {

            return
                accountNotFoundText
        }

        if raw.contains(
            "USER_NOT_AVAILABLE"
        ) {

            return
                userUnavailableText
        }

        return
            genericJoinErrorText
    }

    // MARK: - Localization

    private var joinTitle: String {

        switch localization.language {

        case .hebrew:
            return "הצטרפות ל-TimeUp"

        case .english:
            return "Join TimeUp"

        case .arabic:
            return "الانضمام إلى TimeUp"
        }
    }

    private var joinSubtitle: String {

        switch localization.language {

        case .hebrew:
            return "הזן את הקוד שקיבלת כדי להמשיך"

        case .english:
            return "Enter the code you received to continue"

        case .arabic:
            return "أدخل الرمز الذي تلقيته للمتابعة"
        }
    }

    private var namePlaceholder: String {

        switch localization.language {

        case .hebrew:
            return "השם שלך"

        case .english:
            return "Your name"

        case .arabic:
            return "اسمك"
        }
    }

    private var groupCodePlaceholder: String {

        switch localization.language {

        case .hebrew:
            return "קוד קבוצה"

        case .english:
            return "Group code"

        case .arabic:
            return "رمز المجموعة"
        }
    }

    private var joiningText: String {

        switch localization.language {

        case .hebrew:
            return "מצטרף..."

        case .english:
            return "Joining..."

        case .arabic:
            return "جارٍ الانضمام..."
        }
    }

    private var continueText: String {

        switch localization.language {

        case .hebrew:
            return "המשך"

        case .english:
            return "Continue"

        case .arabic:
            return "متابعة"
        }
    }

    private var groupCodeHelpText: String {

        switch localization.language {

        case .hebrew:
            return "קוד הקבוצה מתקבל ממנהל הקבוצה"

        case .english:
            return "The group code is provided by the group admin"

        case .arabic:
            return "يمكنك الحصول على رمز المجموعة من مدير المجموعة"
        }
    }

    private var doneText: String {

        switch localization.language {

        case .hebrew:
            return "סיום"

        case .english:
            return "Done"

        case .arabic:
            return "تم"
        }
    }

    private var missingNameText: String {

        switch localization.language {

        case .hebrew:
            return "יש להזין שם כדי להמשיך."

        case .english:
            return "Enter your name to continue."

        case .arabic:
            return "أدخل اسمك للمتابعة."
        }
    }

    private var invalidCodeFormatText: String {

        switch localization.language {

        case .hebrew:
            return "יש להזין קוד קבוצה בן 4 ספרות."

        case .english:
            return "Enter a 4-digit group code."

        case .arabic:
            return "أدخل رمز مجموعة مكوّنًا من 4 أرقام."
        }
    }

    private var groupNotFoundText: String {

        switch localization.language {

        case .hebrew:
            return "לא נמצאה קבוצה עם הקוד הזה."

        case .english:
            return "No group was found with this code."

        case .arabic:
            return "لم يتم العثور على مجموعة بهذا الرمز."
        }
    }

    private var invalidGroupCodeText: String {

        switch localization.language {

        case .hebrew:
            return "קוד הקבוצה אינו תקין."

        case .english:
            return "The group code is invalid."

        case .arabic:
            return "رمز المجموعة غير صالح."
        }
    }

    private var alreadyInGroupText: String {

        switch localization.language {

        case .hebrew:
            return "החשבון כבר משויך לקבוצה."

        case .english:
            return "This account is already assigned to a group."

        case .arabic:
            return "هذا الحساب مرتبط بالفعل بمجموعة."
        }
    }

    private var adminCannotJoinText: String {

        switch localization.language {

        case .hebrew:
            return "חשבון מנהל אינו יכול להצטרף כחבר קבוצה."

        case .english:
            return "An admin account cannot join as a group member."

        case .arabic:
            return "لا يمكن لحساب المدير الانضمام كعضو في المجموعة."
        }
    }

    private var sessionExpiredText: String {

        switch localization.language {

        case .hebrew:
            return "החיבור לחשבון הסתיים. יש להתחבר מחדש."

        case .english:
            return "Your session has ended. Please sign in again."

        case .arabic:
            return "انتهت جلسة الحساب. يرجى تسجيل الدخول مرة أخرى."
        }
    }

    private var accountNotFoundText: String {

        switch localization.language {

        case .hebrew:
            return "לא נמצא חשבון TimeUp מחובר."

        case .english:
            return "No connected TimeUp account was found."

        case .arabic:
            return "لم يتم العثور على حساب TimeUp متصل."
        }
    }

    private var userUnavailableText: String {

        switch localization.language {

        case .hebrew:
            return "לא ניתן לטעון את החשבון. יש להתחבר מחדש."

        case .english:
            return "Unable to load the account. Please sign in again."

        case .arabic:
            return "تعذر تحميل الحساب. يرجى تسجيل الدخول مرة أخرى."
        }
    }

    private var genericJoinErrorText: String {

        switch localization.language {

        case .hebrew:
            return "לא ניתן היה להצטרף לקבוצה כרגע. נסה שוב."

        case .english:
            return "Unable to join the group right now. Please try again."

        case .arabic:
            return "تعذر الانضمام إلى المجموعة حاليًا. حاول مرة أخرى."
        }
    }
}

// MARK: - Joined Group

private struct SupabaseJoinedGroupView: View {

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    let groupID: UUID
    let displayName: String

    var body: some View {

        Group {

            if dataStore.isLoading {

                VStack(
                    spacing: 16
                ) {

                    ProgressView()

                    Text(
                        loadingGroupText
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

            } else if let group =
                dataStore.groups.first(
                    where: {
                        $0.id ==
                            groupID
                    }
                )
            {

                VStack(
                    spacing: 24
                ) {

                    Image(
                        systemName:
                            "checkmark.circle.fill"
                    )
                    .font(
                        .system(
                            size: 64
                        )
                    )
                    .foregroundStyle(
                        .green
                    )

                    Text(
                        joinedSuccessfullyText
                    )
                    .font(
                        .largeTitle.bold()
                    )
                    .multilineTextAlignment(
                        .center
                    )

                    Text(
                        group.name
                    )
                    .font(.title2)
                    .fontWeight(
                        .semibold
                    )

                    Text(
                        greetingText
                    )
                    .foregroundStyle(
                        .secondary
                    )

                    Text(
                        groupConnectedText
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
                    unableToLoadGroupTitle,
                    systemImage:
                        "person.3.sequence.fill",
                    description:
                        Text(
                            unableToLoadGroupDescription
                        )
                )
            }
        }
        .task {

            await dataStore
                .loadCurrentAccount()
        }
    }

    // MARK: - Localization

    private var loadingGroupText: String {

        switch localization.language {

        case .hebrew:
            return "טוען את הקבוצה..."

        case .english:
            return "Loading the group..."

        case .arabic:
            return "جارٍ تحميل المجموعة..."
        }
    }

    private var joinedSuccessfullyText: String {

        switch localization.language {

        case .hebrew:
            return "הצטרפת בהצלחה"

        case .english:
            return "You've joined successfully"

        case .arabic:
            return "تم الانضمام بنجاح"
        }
    }

    private var greetingText: String {

        switch localization.language {

        case .hebrew:
            return "שלום \(displayName)"

        case .english:
            return "Hello \(displayName)"

        case .arabic:
            return "مرحبًا \(displayName)"
        }
    }

    private var groupConnectedText: String {

        switch localization.language {

        case .hebrew:
            return "הקבוצה מחוברת כעת לחשבון שלך ב-TimeUp."

        case .english:
            return "The group is now connected to your TimeUp account."

        case .arabic:
            return "المجموعة متصلة الآن بحساب TimeUp الخاص بك."
        }
    }

    private var unableToLoadGroupTitle: String {

        switch localization.language {

        case .hebrew:
            return "לא ניתן לטעון את הקבוצה"

        case .english:
            return "Unable to Load Group"

        case .arabic:
            return "تعذر تحميل المجموعة"
        }
    }

    private var unableToLoadGroupDescription: String {

        switch localization.language {

        case .hebrew:
            return "ההצטרפות נשמרה, אך פרטי הקבוצה עדיין לא נטענו."

        case .english:
            return "Your membership was saved, but the group details have not loaded yet."

        case .arabic:
            return "تم حفظ عضويتك، لكن تفاصيل المجموعة لم يتم تحميلها بعد."
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