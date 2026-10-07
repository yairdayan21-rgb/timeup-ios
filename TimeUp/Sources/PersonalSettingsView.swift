import SwiftUI
import LocalAuthentication

struct PersonalSettingsView: View {

    @ObservedObject private var store =
        TimeUpStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @ObservedObject private var onboardingCoordinator =
        MemberOnboardingCoordinator.shared

    @State private var isAuthenticating = false
    @State private var errorMessage = ""

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

                        Text(
                            language.displayName
                        )
                        .tag(language)
                    }
                }
                .pickerStyle(.navigationLink)

            } header: {

                Text(
                    localization.text(.language)
                )

            } footer: {

                Text(
                    languageFooterText
                )
            }

            // MARK: - Tutorial

            Section {

                Button {

                    onboardingCoordinator
                        .presentReplay()

                } label: {

                    Label(
                        showTutorialAgainText,
                        systemImage:
                            "questionmark.circle"
                    )
                }

            } header: {

                Text(
                    tutorialTitle
                )

            } footer: {

                Text(
                    tutorialFooterText
                )
            }

            // MARK: - Security

            Section {

                Toggle(
                    faceIDToggleText,
                    isOn: Binding(
                        get: {
                            store.isAppLockEnabled
                        },
                        set: { newValue in

                            handleFaceIDChange(
                                newValue
                            )
                        }
                    )
                )
                .disabled(
                    isAuthenticating
                )

            } header: {

                Text(
                    securityTitle
                )

            } footer: {

                Text(
                    securityFooterText
                )
            }

            // MARK: - Authentication Progress

            if isAuthenticating {

                Section {

                    HStack {

                        ProgressView()

                        Text(
                            authenticatingText
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }
            }

            // MARK: - Error

            if !errorMessage.isEmpty {

                Section {

                    Text(
                        errorMessage
                    )
                    .foregroundStyle(
                        .red
                    )
                    .font(
                        .footnote
                    )
                }
            }
        }
        .navigationTitle(
            localization.text(
                .settings
            )
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .environment(
            \.locale,
            localization.language.locale
        )
        .environment(
            \.layoutDirection,
            localization.language.layoutDirection
        )
    }

    // MARK: - Language

    private var languageBinding:
        Binding<TimeUpLanguage> {

        Binding(
            get: {

                localization.language
            },
            set: { newLanguage in

                localization.setLanguage(
                    newLanguage
                )
            }
        )
    }

    private var languageFooterText:
        String {

        switch localization.language {

        case .hebrew:

            return
                "בחר את השפה שבה יוצג TimeUp."

        case .english:

            return
                "Choose the language used throughout TimeUp."

        case .arabic:

            return
                "اختر اللغة التي سيُعرض بها TimeUp."
        }
    }

    // MARK: - Tutorial Text

    private var tutorialTitle:
        String {

        switch localization.language {

        case .hebrew:
            return "הדרכה"

        case .english:
            return "Tutorial"

        case .arabic:
            return "الدليل"
        }
    }

    private var showTutorialAgainText:
        String {

        switch localization.language {

        case .hebrew:
            return "הצג שוב את ההדרכה"

        case .english:
            return "Show Tutorial Again"

        case .arabic:
            return "عرض الدليل مرة أخرى"
        }
    }

    private var tutorialFooterText:
        String {

        switch localization.language {

        case .hebrew:
            return "אפשר לעבור שוב על ההדרכה של TimeUp בכל שלב."

        case .english:
            return "You can view the TimeUp tutorial again at any time."

        case .arabic:
            return "يمكنك عرض دليل TimeUp مرة أخرى في أي وقت."
        }
    }

    // MARK: - Security Text

    private var securityTitle:
        String {

        switch localization.language {

        case .hebrew:
            return "אבטחה"

        case .english:
            return "Security"

        case .arabic:
            return "الأمان"
        }
    }

    private var faceIDToggleText:
        String {

        switch localization.language {

        case .hebrew:

            return
                "נעילת TimeUp עם Face ID"

        case .english:

            return
                "Lock TimeUp with Face ID"

        case .arabic:

            return
                "قفل TimeUp باستخدام Face ID"
        }
    }

    private var securityFooterText:
        String {

        switch localization.language {

        case .hebrew:

            return
                "כאשר ההגנה פעילה, TimeUp יבקש אימות כדי להגן על החשבון."

        case .english:

            return
                "When protection is enabled, TimeUp will require authentication to protect your account."

        case .arabic:

            return
                "عند تفعيل الحماية، سيطلب TimeUp المصادقة لحماية حسابك."
        }
    }

    private var authenticatingText:
        String {

        switch localization.language {

        case .hebrew:
            return "מאמת..."

        case .english:
            return "Authenticating..."

        case .arabic:
            return "جارٍ التحقق..."
        }
    }

    // MARK: - Face ID

    private func handleFaceIDChange(
        _ enabled: Bool
    ) {

        if enabled {

            authenticateAndEnable()

        } else {

            authenticateAndDisable()
        }
    }

    // MARK: - Enable

    private func authenticateAndEnable() {

        authenticate(
            reason:
                authenticationEnableReason
        ) {

            store.setAppLockEnabled(
                true
            )
        }
    }

    // MARK: - Disable

    private func authenticateAndDisable() {

        authenticate(
            reason:
                authenticationDisableReason
        ) {

            store.setAppLockEnabled(
                false
            )
        }
    }

    // MARK: - Authentication Reasons

    private var authenticationEnableReason:
        String {

        switch localization.language {

        case .hebrew:

            return
                "הפעלת הגנת Face ID על TimeUp"

        case .english:

            return
                "Enable Face ID protection for TimeUp"

        case .arabic:

            return
                "تفعيل حماية Face ID لتطبيق TimeUp"
        }
    }

    private var authenticationDisableReason:
        String {

        switch localization.language {

        case .hebrew:

            return
                "אימות לצורך ביטול הגנת Face ID"

        case .english:

            return
                "Authenticate to disable Face ID protection"

        case .arabic:

            return
                "تحقق لإيقاف حماية Face ID"
        }
    }

    // MARK: - Authentication

    private func authenticate(
        reason: String,
        onSuccess:
            @escaping () -> Void
    ) {

        guard !isAuthenticating else {
            return
        }

        isAuthenticating = true
        errorMessage = ""

        let context =
            LAContext()

        context.localizedCancelTitle =
            cancelText

        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &error
        ) else {

            isAuthenticating = false

            errorMessage =
                authenticationUnavailableText

            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) {
            success,
            authenticationError in

            DispatchQueue.main.async {

                isAuthenticating =
                    false

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

    // MARK: - Authentication Error

    private func handleAuthenticationError(
        _ error: Error?
    ) {

        guard let authenticationError =
            error as? LAError
        else {

            errorMessage =
                genericAuthenticationErrorText

            return
        }

        switch authenticationError.code {

        case .userCancel,
             .systemCancel,
             .appCancel:

            errorMessage =
                authenticationCancelledText

        case .authenticationFailed:

            errorMessage =
                authenticationFailedText

        case .biometryNotAvailable:

            errorMessage =
                faceIDUnavailableText

        case .biometryNotEnrolled:

            errorMessage =
                faceIDNotEnrolledText

        case .biometryLockout:

            errorMessage =
                faceIDLockedText

        default:

            errorMessage =
                genericAuthenticationErrorText
        }
    }

    // MARK: - Authentication Localized Text

    private var cancelText:
        String {

        switch localization.language {

        case .hebrew:
            return "ביטול"

        case .english:
            return "Cancel"

        case .arabic:
            return "إلغاء"
        }
    }

    private var authenticationUnavailableText:
        String {

        switch localization.language {

        case .hebrew:

            return
                "לא ניתן להשתמש באימות המכשיר כרגע."

        case .english:

            return
                "Device authentication is currently unavailable."

        case .arabic:

            return
                "مصادقة الجهاز غير متاحة حاليًا."
        }
    }

    private var genericAuthenticationErrorText:
        String {

        switch localization.language {

        case .hebrew:

            return
                "לא ניתן היה להשלים את האימות."

        case .english:

            return
                "Authentication could not be completed."

        case .arabic:

            return
                "تعذر إكمال المصادقة."
        }
    }

    private var authenticationCancelledText:
        String {

        switch localization.language {

        case .hebrew:
            return "האימות בוטל."

        case .english:
            return "Authentication was cancelled."

        case .arabic:
            return "تم إلغاء المصادقة."
        }
    }

    private var authenticationFailedText:
        String {

        switch localization.language {

        case .hebrew:

            return
                "האימות לא הצליח. נסה שוב."

        case .english:

            return
                "Authentication failed. Try again."

        case .arabic:

            return
                "فشلت المصادقة. حاول مرة أخرى."
        }
    }

    private var faceIDUnavailableText:
        String {

        switch localization.language {

        case .hebrew:

            return
                "Face ID אינו זמין במכשיר הזה."

        case .english:

            return
                "Face ID is not available on this device."

        case .arabic:

            return
                "Face ID غير متاح على هذا الجهاز."
        }
    }

    private var faceIDNotEnrolledText:
        String {

        switch localization.language {

        case .hebrew:

            return
                "לא הוגדר Face ID במכשיר."

        case .english:

            return
                "Face ID has not been set up on this device."

        case .arabic:

            return
                "لم يتم إعداد Face ID على هذا الجهاز."
        }
    }

    private var faceIDLockedText:
        String {

        switch localization.language {

        case .hebrew:

            return
                "Face ID נעול זמנית."

        case .english:

            return
                "Face ID is temporarily locked."

        case .arabic:

            return
                "Face ID مقفل مؤقتًا."
        }
    }
}