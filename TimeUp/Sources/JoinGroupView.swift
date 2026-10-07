import SwiftUI
import Supabase

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
    @State private var showAdminApp = false

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

    private struct AdminRegistrationParameters: Encodable {

        let requestedCode: String

        enum CodingKeys: String, CodingKey {
            case requestedCode = "requested_code"
        }
    }

    // MARK: - Code Validation

    private func isAllowedCodeCharacter(
        _ character: Character
    ) -> Bool {

        let scalars = character.unicodeScalars

        guard
            scalars.count == 1,
            let scalar = scalars.first
        else {
            return false
        }

        let value = scalar.value

        return (value >= 65 && value <= 90)
            || (value >= 97 && value <= 122)
            || (value >= 48 && value <= 57)
    }

    private func isValidRegistrationCode(
        _ code: String
    ) -> Bool {

        if code == "0000" {
            return true
        }

        return code.count == 8
            && code.allSatisfy(isAllowedCodeCharacter)
    }

    private var isReadyToJoin: Bool {

        let name = displayName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return isValidRegistrationCode(groupCode)
            && !name.isEmpty
            && !isJoining
    }

    var body: some View {

        ScrollView {

            VStack(spacing: 24) {

                Image(systemName: "person.3.fill")
                    .font(.system(size: 54))
                    .padding(.top, 32)

                VStack(spacing: 8) {

                    Text(joinTitle)
                        .font(
                            .system(
                                size: 30,
                                weight: .bold,
                                design: .rounded
                            )
                        )

                    Text(joinSubtitle)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                TextField(
                    namePlaceholder,
                    text: $displayName
                )
                .accessibilityIdentifier("display-name-field")
                .textInputAutocapitalization(.words)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .focused(
                    $focusedField,
                    equals: .displayName
                )
                .submitLabel(.next)
                .disabled(isJoining)
                .onSubmit {
                    focusedField = .groupCode
                }
                .onChange(of: displayName) { _, _ in
                    errorMessage = nil
                }

                TextField(
                    groupCodePlaceholder,
                    text: $groupCode
                )
                .accessibilityIdentifier("group-code-field")
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .multilineTextAlignment(.center)
                .font(
                    .system(
                        size: 26,
                        weight: .semibold,
                        design: .monospaced
                    )
                )
                .textFieldStyle(.roundedBorder)
                .environment(
                    \.layoutDirection,
                    .leftToRight
                )
                .focused(
                    $focusedField,
                    equals: .groupCode
                )
                .submitLabel(.go)
                .disabled(isJoining)
                .onSubmit {

                    if isReadyToJoin {
                        join()
                    }
                }
                .onChange(of: groupCode) { _, newValue in

                    let normalized = String(
                        newValue
                            .filter(isAllowedCodeCharacter)
                            .prefix(8)
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
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("join-error")
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
                                ? joiningText
                                : continueText
                        )
                        .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .accessibilityIdentifier("join-button")
                .buttonStyle(.borderedProminent)
                .disabled(!isReadyToJoin)

                Text(groupCodeHelpText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItemGroup(placement: .keyboard) {

                Spacer()

                Button(doneText) {
                    focusedField = nil
                }
            }
        }
        .navigationDestination(
            item: $joinedGroupID
        ) { groupID in

            SupabaseJoinedGroupView(
                groupID: groupID,
                displayName: displayName.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            )
            .navigationBarBackButtonHidden(true)
        }
        .navigationDestination(
            isPresented: $showAdminApp
        ) {

            AdminTabView()
                .navigationBarBackButtonHidden(true)
        }
        .task {

            if dataStore.currentUser == nil {
                await dataStore.loadCurrentAccount()
            }
        }
    }

    // MARK: - Registration

    @MainActor
    private func join() {

        guard !isJoining else {
            return
        }

        let name = displayName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let code = groupCode.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        focusedField = nil
        errorMessage = nil

        guard !name.isEmpty else {

            errorMessage = missingNameText
            return
        }

        guard isValidRegistrationCode(code) else {

            errorMessage = invalidCodeFormatText
            return
        }

        isJoining = true

        Task { @MainActor in

            defer {
                isJoining = false
            }

            do {

                if dataStore.currentUser == nil {
                    await dataStore.loadCurrentAccount()
                }

                guard dataStore.currentUser != nil else {
                    throw JoinGroupError.userNotAvailable
                }

                try await dataStore.updateDisplayName(name)

                if code == "0000" {

                    try await registerAdmin(code: code)

                    errorMessage = nil
                    showAdminApp = true

                } else {

                    let groupID = try await dataStore.joinGroup(
                        code: code
                    )

                    errorMessage = nil
                    joinedGroupID = groupID
                }

            } catch {

                errorMessage = message(for: error)
            }
        }
    }

    // MARK: - Admin Registration

    @MainActor
    private func registerAdmin(
        code: String
    ) async throws {

        let registeredUserID: UUID =
            try await SupabaseManager.shared.client
                .rpc(
                    "register_timeup_admin",
                    params: AdminRegistrationParameters(
                        requestedCode: code
                    )
                )
                .execute()
                .value

        await dataStore.loadCurrentAccount()

        guard
            let currentUser = dataStore.currentUser,
            currentUser.id == registeredUserID,
            dataStore.isAdmin
        else {
            throw JoinGroupError.adminNotConfirmed
        }
    }

    // MARK: - Errors

    private func message(
        for error: Error
    ) -> String {

        let raw = (
            error.localizedDescription
                + " "
                + String(describing: error)
        )
        .uppercased()

        if raw.contains("ADMIN_CODE_ALREADY_USED") {

            return localized(
                "כבר קיים חשבון מנהל במערכת. הקוד 0000 אינו זמין.",
                "An admin account already exists. Code 0000 is unavailable.",
                "يوجد حساب مدير بالفعل. الرمز 0000 غير متاح."
            )
        }

        if raw.contains("INVALID_ADMIN_CODE") {

            return localized(
                "קוד המנהל אינו תקין.",
                "The admin code is invalid.",
                "رمز المدير غير صالح."
            )
        }

        if raw.contains("ADMIN_REGISTRATION_NOT_CONFIGURED") {

            return localized(
                "הרשמת מנהל אינה זמינה כרגע. נסה שוב מאוחר יותר.",
                "Admin registration is currently unavailable. Please try again later.",
                "تسجيل المدير غير متاح حاليًا. حاول مرة أخرى لاحقًا."
            )
        }

        if raw.contains("ADMIN_NOT_CONFIRMED") {

            return localized(
                "לא ניתן לאמת כרגע את חשבון המנהל. נסה שוב; הרשמה שכבר נשמרה לא תיצור חשבון נוסף.",
                "Unable to verify the admin account right now. Try again; a saved registration will not create another account.",
                "تعذر التحقق من حساب المدير حاليًا. حاول مجددًا؛ لن ينشئ التسجيل المحفوظ حسابًا آخر."
            )
        }

        if raw.contains("ADMIN_REGISTRATION_FAILED") {

            return localized(
                "לא ניתן להשלים את הרשמת המנהל כרגע. נסה שוב.",
                "Unable to complete admin registration right now. Please try again.",
                "تعذر إكمال تسجيل المدير حاليًا. حاول مرة أخرى."
            )
        }

        if raw.contains("INVALID_USER_ROLE") {

            return localized(
                "החשבון אינו מתאים למסלול ההרשמה הזה.",
                "This account cannot use this registration flow.",
                "لا يمكن لهذا الحساب استخدام مسار التسجيل هذا."
            )
        }

        if raw.contains("GROUP_NOT_FOUND") {
            return groupNotFoundText
        }

        if raw.contains("INVALID_GROUP_CODE") {
            return invalidGroupCodeText
        }

        if raw.contains("ALREADY_IN_GROUP") {
            return alreadyInGroupText
        }

        if raw.contains("ADMIN_CANNOT_JOIN_AS_MEMBER") {
            return adminCannotJoinText
        }

        if raw.contains("NOT_AUTHENTICATED") {
            return sessionExpiredText
        }

        if raw.contains("TIMEUP_USER_NOT_FOUND") {
            return accountNotFoundText
        }

        if raw.contains("USER_NOT_AVAILABLE") {
            return userUnavailableText
        }

        return genericJoinErrorText
    }

    // MARK: - Localization

    private func localized(
        _ hebrew: String,
        _ english: String,
        _ arabic: String
    ) -> String {

        switch localization.language {

        case .hebrew:
            return hebrew

        case .english:
            return english

        case .arabic:
            return arabic
        }
    }

    private var joinTitle: String {

        localized(
            "הצטרפות ל-TimeUp",
            "Join TimeUp",
            "الانضمام إلى TimeUp"
        )
    }

    private var joinSubtitle: String {

        localized(
            "הזן את הקוד שקיבלת כדי להמשיך",
            "Enter the code you received to continue",
            "أدخل الرمز الذي تلقيته للمتابعة"
        )
    }

    private var namePlaceholder: String {

        localized(
            "השם שלך",
            "Your name",
            "اسمك"
        )
    }

    private var groupCodePlaceholder: String {

        localized(
            "קוד קבוצה",
            "Group code",
            "رمز المجموعة"
        )
    }

    private var joiningText: String {

        localized(
            "מצטרף...",
            "Joining...",
            "جارٍ الانضمام..."
        )
    }

    private var continueText: String {

        localized(
            "המשך",
            "Continue",
            "متابعة"
        )
    }

    private var groupCodeHelpText: String {

        localized(
            "קוד הקבוצה מתקבל מהמנהל ומכיל 8 תווים: אותיות באנגלית ומספרים. יש להקליד אותיות גדולות וקטנות בדיוק כפי שקיבלת.",
            "Your group admin provides an 8-character code containing English letters and numbers. Enter uppercase and lowercase letters exactly as shown.",
            "يقدم مدير المجموعة رمزًا من 8 أحرف يتضمن حروفًا إنجليزية وأرقامًا. أدخل الحروف الكبيرة والصغيرة تمامًا كما تظهر."
        )
    }

    private var doneText: String {

        localized(
            "סיום",
            "Done",
            "تم"
        )
    }

    private var missingNameText: String {

        localized(
            "יש להזין שם כדי להמשיך.",
            "Enter your name to continue.",
            "أدخل اسمك للمتابعة."
        )
    }

    private var invalidCodeFormatText: String {

        localized(
            "יש להזין קוד קבוצה בן 8 תווים הכולל אותיות באנגלית ומספרים.",
            "Enter an 8-character group code using English letters and numbers.",
            "أدخل رمز مجموعة من 8 أحرف باستخدام الحروف الإنجليزية والأرقام."
        )
    }

    private var groupNotFoundText: String {

        localized(
            "לא נמצאה קבוצה עם הקוד הזה. בדוק גם את האותיות הגדולות והקטנות.",
            "No group was found with this code. Check uppercase and lowercase letters.",
            "لم يتم العثور على مجموعة بهذا الرمز. تحقق من الحروف الكبيرة والصغيرة."
        )
    }

    private var invalidGroupCodeText: String {

        localized(
            "קוד הקבוצה אינו תקין.",
            "The group code is invalid.",
            "رمز المجموعة غير صالح."
        )
    }

    private var alreadyInGroupText: String {

        localized(
            "החשבון כבר משויך לקבוצה.",
            "This account is already assigned to a group.",
            "هذا الحساب مرتبط بالفعل بمجموعة."
        )
    }

    private var adminCannotJoinText: String {

        localized(
            "חשבון מנהל אינו יכול להצטרף כחבר קבוצה.",
            "An admin account cannot join as a group member.",
            "لا يمكن لحساب المدير الانضمام كعضو في المجموعة."
        )
    }

    private var sessionExpiredText: String {

        localized(
            "החיבור לחשבון הסתיים. יש להתחבר מחדש.",
            "Your session has ended. Please sign in again.",
            "انتهت جلسة الحساب. يرجى تسجيل الدخول مرة أخرى."
        )
    }

    private var accountNotFoundText: String {

        localized(
            "לא נמצא חשבון TimeUp מחובר.",
            "No connected TimeUp account was found.",
            "لم يتم العثور على حساب TimeUp متصل."
        )
    }

    private var userUnavailableText: String {

        localized(
            "לא ניתן לטעון את החשבון. יש להתחבר מחדש.",
            "Unable to load the account. Please sign in again.",
            "تعذر تحميل الحساب. يرجى تسجيل الدخول مرة أخرى."
        )
    }

    private var genericJoinErrorText: String {

        localized(
            "לא ניתן להשלים את ההצטרפות כרגע. נסה שוב.",
            "Unable to complete registration right now. Please try again.",
            "تعذر إكمال التسجيل حاليًا. حاول مرة أخرى."
        )
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

                VStack(spacing: 16) {

                    ProgressView()

                    Text(loadingGroupText)
                        .foregroundStyle(.secondary)
                }

            } else if let group = dataStore.groups.first(
                where: { $0.id == groupID }
            ) {

                VStack(spacing: 24) {

                    Image(
                        systemName: "checkmark.circle.fill"
                    )
                    .font(.system(size: 64))
                    .foregroundStyle(.green)

                    Text(joinedSuccessfullyText)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text(group.name)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(greetingText)
                        .foregroundStyle(.secondary)

                    Text(groupConnectedText)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding(24)

            } else {

                ContentUnavailableView(
                    unableToLoadGroupTitle,
                    systemImage: "person.3.sequence.fill",
                    description: Text(
                        unableToLoadGroupDescription
                    )
                )
            }
        }
        .task {
            await dataStore.loadCurrentAccount()
        }
    }

    // MARK: - Localization

    private func localized(
        _ hebrew: String,
        _ english: String,
        _ arabic: String
    ) -> String {

        switch localization.language {

        case .hebrew:
            return hebrew

        case .english:
            return english

        case .arabic:
            return arabic
        }
    }

    private var loadingGroupText: String {

        localized(
            "טוען את הקבוצה...",
            "Loading the group...",
            "جارٍ تحميل المجموعة..."
        )
    }

    private var joinedSuccessfullyText: String {

        localized(
            "הצטרפת בהצלחה",
            "You've joined successfully",
            "تم الانضمام بنجاح"
        )
    }

    private var greetingText: String {

        localized(
            "שלום \(displayName)",
            "Hello \(displayName)",
            "مرحبًا \(displayName)"
        )
    }

    private var groupConnectedText: String {

        localized(
            "הקבוצה מחוברת כעת לחשבון שלך ב-TimeUp.",
            "The group is now connected to your TimeUp account.",
            "المجموعة متصلة الآن بحساب TimeUp الخاص بك."
        )
    }

    private var unableToLoadGroupTitle: String {

        localized(
            "לא ניתן לטעון את הקבוצה",
            "Unable to Load Group",
            "تعذر تحميل المجموعة"
        )
    }

    private var unableToLoadGroupDescription: String {

        localized(
            "ההצטרפות נשמרה, אך פרטי הקבוצה עדיין לא נטענו.",
            "Your membership was saved, but the group details have not loaded yet.",
            "تم حفظ عضويتك، لكن تفاصيل المجموعة لم يتم تحميلها بعد."
        )
    }
}

// MARK: - Registration Errors

private enum JoinGroupError: LocalizedError {

    case userNotAvailable
    case adminNotConfirmed

    var errorDescription: String? {

        switch self {

        case .userNotAvailable:
            return "USER_NOT_AVAILABLE"

        case .adminNotConfirmed:
            return "ADMIN_NOT_CONFIRMED"
        }
    }
}