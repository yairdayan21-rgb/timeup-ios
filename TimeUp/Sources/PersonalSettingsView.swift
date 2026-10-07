import SwiftUI
import LocalAuthentication
import Supabase

struct PersonalSettingsView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var store =
        TimeUpStore.shared

    @ObservedObject private var dataStore =
        SupabaseDataStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @ObservedObject private var onboardingCoordinator =
        MemberOnboardingCoordinator.shared

    @State private var isAuthenticating = false
    @State private var isDeletingAccount = false
    @State private var errorMessage = ""

    @State private var showAdminDeletionOptions = false
    @State private var showDeletionConfirmation = false
    @State private var pendingDeletion: DeletionChoice?

    private enum DeletionChoice {
        case memberAccount
        case keepGroups
        case deleteGroups

        var deleteGroupsParameter: Bool? {
            switch self {
            case .memberAccount:
                return nil
            case .keepGroups:
                return false
            case .deleteGroups:
                return true
            }
        }
    }

    private struct AccountDeletionParameters: Encodable {

        let deleteGroups: Bool?

        enum CodingKeys: String, CodingKey {
            case deleteGroups = "delete_groups"
        }
    }

    private var isBusy: Bool {
        isAuthenticating || isDeletingAccount
    }

    var body: some View {

        Form {

            // MARK: - Language

            Section {

                Picker(
                    localization.text(.language),
                    selection: languageBinding
                ) {

                    ForEach(
                        TimeUpLanguage.allCases
                    ) { language in

                        Text(language.displayName)
                            .tag(language)
                    }
                }
                .pickerStyle(.navigationLink)

            } header: {

                Text(localization.text(.language))

            } footer: {

                Text(languageFooterText)
            }

            // MARK: - Member Tutorial

            if dataStore.isMember {

                Section {

                    Button {

                        onboardingCoordinator.presentReplay()

                    } label: {

                        Label(
                            showTutorialAgainText,
                            systemImage: "questionmark.circle"
                        )
                    }

                } header: {

                    Text(tutorialTitle)

                } footer: {

                    Text(tutorialFooterText)
                }
            }

            // MARK: - Security

            Section {

                Toggle(
                    faceIDToggleText,
                    isOn: Binding(
                        get: {
                            store.isAppLockEnabled
                        },
                        set: { enabled in
                            handleFaceIDChange(enabled)
                        }
                    )
                )

            } header: {

                Text(securityTitle)

            } footer: {

                Text(securityFooterText)
            }

            // MARK: - Account

            if dataStore.currentUser != nil {

                Section {

                    Button(role: .destructive) {
                        requestAccountDeletion()
                    } label: {

                        Label(
                            deleteAccountText,
                            systemImage: "person.crop.circle.badge.minus"
                        )
                    }
                    .accessibilityIdentifier(
                        "delete-account-button"
                    )

                } header: {

                    Text(accountTitle)

                } footer: {

                    Text(accountFooterText)
                }
            }

            // MARK: - Progress

            if isAuthenticating || isDeletingAccount {

                Section {

                    HStack(spacing: 12) {

                        ProgressView()

                        Text(
                            isDeletingAccount
                                ? deletingAccountText
                                : authenticatingText
                        )
                        .foregroundStyle(.secondary)
                    }
                }
            }

            // MARK: - Error

            if !errorMessage.isEmpty {

                Section {

                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .disabled(isBusy)
        .navigationTitle(
            localization.text(.settings)
        )
        .navigationBarTitleDisplayMode(.inline)
        .environment(
            \.locale,
            localization.language.locale
        )
        .environment(
            \.layoutDirection,
            localization.language.layoutDirection
        )
        .interactiveDismissDisabled(isDeletingAccount)
        .sheet(
            isPresented: $showAdminDeletionOptions,
            onDismiss: {

                if pendingDeletion != nil {
                    showDeletionConfirmation = true
                }
            }
        ) {

            adminDeletionOptionsView
        }
        .alert(
            deletionConfirmationTitle,
            isPresented: $showDeletionConfirmation
        ) {

            Button(
                cancelText,
                role: .cancel
            ) {
                pendingDeletion = nil
            }

            Button(
                confirmDeletionText,
                role: .destructive
            ) {
                confirmAccountDeletion()
            }

        } message: {

            Text(deletionConfirmationMessage)
        }
    }

    // MARK: - Admin Deletion Options

    private var adminDeletionOptionsView: some View {

        NavigationStack {

            Form {

                Section {

                    Text(
                        localized(
                            "מה תרצה לעשות עם הקבוצות כאשר חשבון המנהל שלך יימחק?",
                            "What would you like to do with the groups when your admin account is deleted?",
                            "ماذا تريد أن تفعل بالمجموعات عند حذف حساب المدير الخاص بك؟"
                        )
                    )

                } footer: {

                    Text(
                        localized(
                            "הקוד 0000 יתפנה רק אחרי שמחיקת החשבון תושלם.",
                            "Code 0000 becomes available only after account deletion is complete.",
                            "سيصبح الرمز 0000 متاحًا فقط بعد اكتمال حذف الحساب."
                        )
                    )
                }

                Section {

                    Button {

                        pendingDeletion = .keepGroups
                        showAdminDeletionOptions = false

                    } label: {

                        Label(
                            localized(
                                "שמור את הקבוצות למנהל הבא",
                                "Keep groups for the next admin",
                                "الاحتفاظ بالمجموعات للمدير التالي"
                            ),
                            systemImage: "person.3.fill"
                        )
                    }

                } footer: {

                    Text(
                        localized(
                            "הקבוצות יישארו במערכת והחברים יישארו משויכים אליהן.",
                            "Groups remain in the system and members stay assigned to them.",
                            "ستبقى المجموعات في النظام وسيظل الأعضاء مرتبطين بها."
                        )
                    )
                }

                Section {

                    Button(role: .destructive) {

                        pendingDeletion = .deleteGroups
                        showAdminDeletionOptions = false

                    } label: {

                        Label(
                            localized(
                                "מחק גם את הקבוצות והנתונים שלהן",
                                "Also delete groups and their data",
                                "حذف المجموعات وبياناتها أيضًا"
                            ),
                            systemImage: "trash"
                        )
                    }

                } footer: {

                    Text(
                        localized(
                            "חשבונות החברים יישארו, אך הם יצטרכו להצטרף לקבוצה מחדש.",
                            "Member accounts remain, but they will need to join a group again.",
                            "ستبقى حسابات الأعضاء، لكن سيتعين عليهم الانضمام إلى مجموعة مجددًا."
                        )
                    )
                }
            }
            .navigationTitle(
                localized(
                    "מחיקת חשבון מנהל",
                    "Delete Admin Account",
                    "حذف حساب المدير"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button(cancelText) {

                        pendingDeletion = nil
                        showAdminDeletionOptions = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .environment(
            \.locale,
            localization.language.locale
        )
        .environment(
            \.layoutDirection,
            localization.language.layoutDirection
        )
    }

    // MARK: - Account Deletion

    @MainActor
    private func requestAccountDeletion() {

        guard !isBusy else {
            return
        }

        guard dataStore.currentUser != nil else {
            errorMessage = accountUnavailableText
            return
        }

        errorMessage = ""
        pendingDeletion = nil

        if dataStore.isAdmin {
            showAdminDeletionOptions = true
        } else if dataStore.isMember {
            pendingDeletion = .memberAccount
            showDeletionConfirmation = true
        } else {
            errorMessage = accountUnavailableText
        }
    }

    @MainActor
    private func confirmAccountDeletion() {

        guard
            !isBusy,
            let choice = pendingDeletion
        else {
            return
        }

        pendingDeletion = nil
        errorMessage = ""
        isDeletingAccount = true

        Task { @MainActor in

            defer {
                isDeletingAccount = false
            }

            do {

                let deleted: Bool =
                    try await SupabaseManager.shared.client
                        .rpc(
                            "delete_current_timeup_account",
                            params: AccountDeletionParameters(
                                deleteGroups:
                                    choice.deleteGroupsParameter
                            )
                        )
                        .execute()
                        .value

                guard deleted else {

                    errorMessage = deletionFailedText
                    return
                }

                // The server has confirmed account deletion.
                // Clear the device session and loaded account.
                try? await SupabaseManager.shared.client
                    .auth
                    .signOut(scope: .local)

                onboardingCoordinator.dismiss()
                store.setAppLockEnabled(false)
                dataStore.reset()

                dismiss()

            } catch {

                errorMessage = deletionMessage(for: error)
            }
        }
    }

    private func deletionMessage(
        for error: Error
    ) -> String {

        let raw = (
            error.localizedDescription
                + " "
                + String(describing: error)
        )
        .uppercased()

        if raw.contains("NOT_AUTHENTICATED") {

            return localized(
                "החיבור לחשבון הסתיים. יש להתחבר מחדש לפני מחיקת החשבון.",
                "Your session has ended. Sign in again before deleting your account.",
                "انتهت جلسة الحساب. سجّل الدخول مجددًا قبل حذف حسابك."
            )
        }

        if raw.contains("TIMEUP_USER_NOT_FOUND") {
            return accountUnavailableText
        }

        if raw.contains("ADMIN_GROUP_CHOICE_REQUIRED") {

            return localized(
                "יש לבחור מה לעשות עם הקבוצות לפני מחיקת חשבון המנהל.",
                "Choose what to do with the groups before deleting the admin account.",
                "اختر ما تريد فعله بالمجموعات قبل حذف حساب المدير."
            )
        }

        if raw.contains("ADMIN_REGISTRATION_MISMATCH")
            || raw.contains("ADMIN_REGISTRATION_NOT_CONFIGURED")
        {

            return localized(
                "לא ניתן לאמת את רישום המנהל כרגע. החשבון לא נמחק.",
                "Unable to verify the admin registration right now. The account was not deleted.",
                "تعذر التحقق من تسجيل المدير حاليًا. لم يتم حذف الحساب."
            )
        }

        if raw.contains("AUTH_ACCOUNT_DELETION_FAILED") {

            return localized(
                "מחיקת חשבון ההתחברות לא הושלמה. נסה שוב.",
                "Deletion of the sign-in account could not be completed. Please try again.",
                "تعذر إكمال حذف حساب تسجيل الدخول. حاول مرة أخرى."
            )
        }

        return deletionFailedText
    }

    // MARK: - Deletion Text

    private var accountTitle: String {
        localized(
            "חשבון",
            "Account",
            "الحساب"
        )
    }

    private var deleteAccountText: String {
        localized(
            "מחק את החשבון שלי",
            "Delete My Account",
            "حذف حسابي"
        )
    }

    private var accountFooterText: String {

        if dataStore.isAdmin {

            return localized(
                "לפני מחיקת החשבון תוכל לבחור אם לשמור את הקבוצות למנהל הבא או למחוק אותן.",
                "Before deleting your account, you can choose whether to keep groups for the next admin or delete them.",
                "قبل حذف حسابك، يمكنك اختيار الاحتفاظ بالمجموعات للمدير التالي أو حذفها."
            )
        }

        return localized(
            "מחיקת החשבון תסיר את השיוך לקבוצה ואת הנתונים האישיים שלך מ-TimeUp.",
            "Deleting your account removes your group membership and personal TimeUp data.",
            "سيؤدي حذف الحساب إلى إزالة عضويتك في المجموعة وبياناتك الشخصية من TimeUp."
        )
    }

    private var deletionConfirmationTitle: String {
        localized(
            "למחוק את החשבון?",
            "Delete Account?",
            "حذف الحساب؟"
        )
    }

    private var confirmDeletionText: String {

        if pendingDeletion == .deleteGroups {

            return localized(
                "מחק את החשבון והקבוצות",
                "Delete Account and Groups",
                "حذف الحساب والمجموعات"
            )
        }

        return localized(
            "מחק את החשבון",
            "Delete Account",
            "حذف الحساب"
        )
    }

    private var deletionConfirmationMessage: String {

        switch pendingDeletion {

        case .keepGroups:

            return localized(
                "החשבון והנתונים האישיים שלך יימחקו לצמיתות. הקבוצות יישמרו למנהל הבא והקוד 0000 יתפנה. לא ניתן לבטל את המחיקה.",
                "Your account and personal data will be permanently deleted. Groups will remain for the next admin and code 0000 will become available. This cannot be undone.",
                "سيتم حذف حسابك وبياناتك الشخصية نهائيًا. ستبقى المجموعات للمدير التالي وسيصبح الرمز 0000 متاحًا. لا يمكن التراجع عن الحذف."
            )

        case .deleteGroups:

            return localized(
                "החשבון שלך, הקבוצות שיצרת והנתונים שלהן יימחקו לצמיתות. חשבונות החברים יישארו והקוד 0000 יתפנה. לא ניתן לבטל את המחיקה.",
                "Your account, the groups you created and their data will be permanently deleted. Member accounts will remain and code 0000 will become available. This cannot be undone.",
                "سيتم حذف حسابك والمجموعات التي أنشأتها وبياناتها نهائيًا. ستبقى حسابات الأعضاء وسيصبح الرمز 0000 متاحًا. لا يمكن التراجع عن الحذف."
            )

        case .memberAccount, .none:

            return localized(
                "החשבון, השיוך לקבוצה והנתונים האישיים שלך יימחקו לצמיתות. לא ניתן לבטל את המחיקה.",
                "Your account, group membership and personal data will be permanently deleted. This cannot be undone.",
                "سيتم حذف حسابك وعضويتك في المجموعة وبياناتك الشخصية نهائيًا. لا يمكن التراجع عن الحذف."
            )
        }
    }

    private var deletingAccountText: String {
        localized(
            "מוחק את החשבון...",
            "Deleting account...",
            "جارٍ حذف الحساب..."
        )
    }

    private var accountUnavailableText: String {
        localized(
            "לא ניתן לטעון את החשבון. יש להתחבר מחדש.",
            "Unable to load the account. Please sign in again.",
            "تعذر تحميل الحساب. يرجى تسجيل الدخول مجددًا."
        )
    }

    private var deletionFailedText: String {
        localized(
            "לא ניתן להשלים את מחיקת החשבון כרגע. בדוק את החיבור ונסה שוב.",
            "Unable to complete account deletion right now. Check your connection and try again.",
            "تعذر إكمال حذف الحساب حاليًا. تحقق من الاتصال وحاول مرة أخرى."
        )
    }

    // MARK: - Language

    private var languageBinding: Binding<TimeUpLanguage> {

        Binding(
            get: {
                localization.language
            },
            set: { language in
                localization.setLanguage(language)
            }
        )
    }

    private var languageFooterText: String {
        localized(
            "בחר את השפה שבה יוצג TimeUp.",
            "Choose the language used throughout TimeUp.",
            "اختر اللغة التي سيُعرض بها TimeUp."
        )
    }

    // MARK: - Tutorial Text

    private var tutorialTitle: String {
        localized(
            "הדרכה",
            "Tutorial",
            "الدليل"
        )
    }

    private var showTutorialAgainText: String {
        localized(
            "הצג שוב את ההדרכה",
            "Show Tutorial Again",
            "عرض الدليل مرة أخرى"
        )
    }

    private var tutorialFooterText: String {
        localized(
            "אפשר לעבור שוב על ההדרכה של TimeUp בכל שלב.",
            "You can view the TimeUp tutorial again at any time.",
            "يمكنك عرض دليل TimeUp مرة أخرى في أي وقت."
        )
    }

    // MARK: - Security Text

    private var securityTitle: String {
        localized(
            "אבטחה",
            "Security",
            "الأمان"
        )
    }

    private var faceIDToggleText: String {
        localized(
            "נעילת TimeUp עם Face ID",
            "Lock TimeUp with Face ID",
            "قفل TimeUp باستخدام Face ID"
        )
    }

    private var securityFooterText: String {
        localized(
            "כאשר ההגנה פעילה, TimeUp יבקש אימות כדי להגן על החשבון.",
            "When protection is enabled, TimeUp will require authentication to protect your account.",
            "عند تفعيل الحماية، سيطلب TimeUp المصادقة لحماية حسابك."
        )
    }

    private var authenticatingText: String {
        localized(
            "מאמת...",
            "Authenticating...",
            "جارٍ التحقق..."
        )
    }

    // MARK: - Face ID

    private func handleFaceIDChange(
        _ enabled: Bool
    ) {

        authenticate(
            reason: enabled
                ? authenticationEnableReason
                : authenticationDisableReason
        ) {
            store.setAppLockEnabled(enabled)
        }
    }

    private var authenticationEnableReason: String {
        localized(
            "הפעלת הגנת Face ID על TimeUp",
            "Enable Face ID protection for TimeUp",
            "تفعيل حماية Face ID لتطبيق TimeUp"
        )
    }

    private var authenticationDisableReason: String {
        localized(
            "אימות לצורך ביטול הגנת Face ID",
            "Authenticate to disable Face ID protection",
            "تحقق لإيقاف حماية Face ID"
        )
    }

    private func authenticate(
        reason: String,
        onSuccess: @escaping () -> Void
    ) {

        guard !isBusy else {
            return
        }

        isAuthenticating = true
        errorMessage = ""

        let context = LAContext()
        context.localizedCancelTitle = cancelText

        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &error
        ) else {

            isAuthenticating = false
            errorMessage = authenticationUnavailableText
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) { success, authenticationError in

            DispatchQueue.main.async {

                isAuthenticating = false

                if success {

                    errorMessage = ""
                    onSuccess()

                } else {

                    handleAuthenticationError(
                        authenticationError
                    )
                }
            }
        }
    }

    private func handleAuthenticationError(
        _ error: Error?
    ) {

        guard let authenticationError = error as? LAError else {

            errorMessage = genericAuthenticationErrorText
            return
        }

        switch authenticationError.code {

        case .userCancel, .systemCancel, .appCancel:
            errorMessage = authenticationCancelledText

        case .authenticationFailed:
            errorMessage = authenticationFailedText

        case .biometryNotAvailable:
            errorMessage = faceIDUnavailableText

        case .biometryNotEnrolled:
            errorMessage = faceIDNotEnrolledText

        case .biometryLockout:
            errorMessage = faceIDLockedText

        default:
            errorMessage = genericAuthenticationErrorText
        }
    }

    // MARK: - Authentication Text

    private var cancelText: String {
        localized(
            "ביטול",
            "Cancel",
            "إلغاء"
        )
    }

    private var authenticationUnavailableText: String {
        localized(
            "לא ניתן להשתמש באימות המכשיר כרגע.",
            "Device authentication is currently unavailable.",
            "مصادقة الجهاز غير متاحة حاليًا."
        )
    }

    private var genericAuthenticationErrorText: String {
        localized(
            "לא ניתן היה להשלים את האימות.",
            "Authentication could not be completed.",
            "تعذر إكمال المصادقة."
        )
    }

    private var authenticationCancelledText: String {
        localized(
            "האימות בוטל.",
            "Authentication was cancelled.",
            "تم إلغاء المصادقة."
        )
    }

    private var authenticationFailedText: String {
        localized(
            "האימות לא הצליח. נסה שוב.",
            "Authentication failed. Try again.",
            "فشلت المصادقة. حاول مرة أخرى."
        )
    }

    private var faceIDUnavailableText: String {
        localized(
            "Face ID אינו זמין במכשיר הזה.",
            "Face ID is not available on this device.",
            "Face ID غير متاح على هذا الجهاز."
        )
    }

    private var faceIDNotEnrolledText: String {
        localized(
            "לא הוגדר Face ID במכשיר.",
            "Face ID has not been set up on this device.",
            "لم يتم إعداد Face ID على هذا الجهاز."
        )
    }

    private var faceIDLockedText: String {
        localized(
            "Face ID נעול זמנית.",
            "Face ID is temporarily locked.",
            "Face ID مقفل مؤقتًا."
        )
    }

    // MARK: - Localization Helper

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
}