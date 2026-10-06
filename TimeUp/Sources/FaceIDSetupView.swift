import SwiftUI
import LocalAuthentication

struct FaceIDSetupView: View {

    let member: TimeUpMember

    @ObservedObject private var store =
        TimeUpStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @State private var isAuthenticating = false
    @State private var errorMessage = ""
    @State private var setupCompleted = false

    var body: some View {

        Group {

            if setupCompleted {

                destinationView

            } else {

                setupView
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Setup Screen

    private var setupView: some View {

        VStack(spacing: 24) {

            Spacer()

            Image(systemName: "faceid")
                .font(
                    .system(size: 72)
                )

            VStack(spacing: 10) {

                Text(protectTimeUpText)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(faceIDDescriptionText)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if !errorMessage.isEmpty {

                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Button {

                enableFaceID()

            } label: {

                HStack {

                    if isAuthenticating {

                        ProgressView()

                    } else {

                        Image(
                            systemName: "faceid"
                        )
                    }

                    Text(
                        isAuthenticating
                            ? authenticatingText
                            : enableFaceIDText
                    )
                    .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isAuthenticating)

            Button {

                continueWithoutFaceID()

            } label: {

                Text(notNowText)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.bordered)
            .disabled(isAuthenticating)
        }
        .padding(24)
    }

    // MARK: - Destination

    @ViewBuilder
    private var destinationView: some View {

        switch member.role {

        case .admin:

            AdminHomeView()
                .navigationBarBackButtonHidden(true)

        case .member:

            MemberTabView()
                .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: - Enable Face ID

    private func enableFaceID() {

        guard !isAuthenticating else {
            return
        }

        isAuthenticating = true
        errorMessage = ""

        let context = LAContext()

        context.localizedCancelTitle =
            cancelText

        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &error
        ) else {

            isAuthenticating = false

            errorMessage =
                deviceAuthenticationUnavailableText

            return
        }

        let reason =
            enableProtectionReasonText

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) {
            success,
            authenticationError in

            DispatchQueue.main.async {

                isAuthenticating = false

                if success {

                    store.setAppLockEnabled(
                        true
                    )

                    setupCompleted = true

                } else {

                    store.setAppLockEnabled(
                        false
                    )

                    if let authenticationError =
                        authenticationError
                            as? LAError
                    {

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
                                authenticationCouldNotCompleteText
                        }

                    } else {

                        errorMessage =
                            authenticationCouldNotCompleteText
                    }
                }
            }
        }
    }

    // MARK: - Skip

    private func continueWithoutFaceID() {

        store.setAppLockEnabled(
            false
        )

        setupCompleted = true
    }

    // MARK: - Localization

    private var protectTimeUpText: String {

        switch localization.language {

        case .hebrew:
            return "להגן על TimeUp?"

        case .english:
            return "Protect TimeUp?"

        case .arabic:
            return "هل تريد حماية TimeUp؟"
        }
    }

    private var faceIDDescriptionText: String {

        switch localization.language {

        case .hebrew:
            return "אפשר להשתמש ב-Face ID כדי להגן על הכניסה לחשבון שלך."

        case .english:
            return "You can use Face ID to protect access to your account."

        case .arabic:
            return "يمكنك استخدام Face ID لحماية الوصول إلى حسابك."
        }
    }

    private var authenticatingText: String {

        switch localization.language {

        case .hebrew:
            return "מאמת..."

        case .english:
            return "Authenticating..."

        case .arabic:
            return "جارٍ التحقق..."
        }
    }

    private var enableFaceIDText: String {

        switch localization.language {

        case .hebrew:
            return "הפעל Face ID"

        case .english:
            return "Enable Face ID"

        case .arabic:
            return "تفعيل Face ID"
        }
    }

    private var notNowText: String {

        switch localization.language {

        case .hebrew:
            return "לא עכשיו"

        case .english:
            return "Not now"

        case .arabic:
            return "ليس الآن"
        }
    }

    private var cancelText: String {

        switch localization.language {

        case .hebrew:
            return "ביטול"

        case .english:
            return "Cancel"

        case .arabic:
            return "إلغاء"
        }
    }

    private var enableProtectionReasonText: String {

        switch localization.language {

        case .hebrew:
            return "הפעלת הגנה על TimeUp"

        case .english:
            return "Enable protection for TimeUp"

        case .arabic:
            return "تفعيل الحماية لـ TimeUp"
        }
    }

    private var deviceAuthenticationUnavailableText: String {

        switch localization.language {

        case .hebrew:
            return "לא ניתן להשתמש באימות המכשיר כרגע."

        case .english:
            return "Device authentication is currently unavailable."

        case .arabic:
            return "التحقق من هوية الجهاز غير متاح حاليًا."
        }
    }

    private var authenticationCancelledText: String {

        switch localization.language {

        case .hebrew:
            return "האימות בוטל. אפשר לנסות שוב או לבחור לא עכשיו."

        case .english:
            return "Authentication was cancelled. You can try again or choose Not now."

        case .arabic:
            return "تم إلغاء التحقق. يمكنك المحاولة مرة أخرى أو اختيار ليس الآن."
        }
    }

    private var authenticationFailedText: String {

        switch localization.language {

        case .hebrew:
            return "האימות לא הצליח. נסה שוב."

        case .english:
            return "Authentication failed. Please try again."

        case .arabic:
            return "فشل التحقق. حاول مرة أخرى."
        }
    }

    private var faceIDUnavailableText: String {

        switch localization.language {

        case .hebrew:
            return "Face ID אינו זמין במכשיר הזה."

        case .english:
            return "Face ID is not available on this device."

        case .arabic:
            return "Face ID غير متاح على هذا الجهاز."
        }
    }

    private var faceIDNotEnrolledText: String {

        switch localization.language {

        case .hebrew:
            return "לא הוגדר Face ID במכשיר."

        case .english:
            return "Face ID has not been set up on this device."

        case .arabic:
            return "لم يتم إعداد Face ID على هذا الجهاز."
        }
    }

    private var faceIDLockedText: String {

        switch localization.language {

        case .hebrew:
            return "Face ID נעול זמנית."

        case .english:
            return "Face ID is temporarily locked."

        case .arabic:
            return "تم قفل Face ID مؤقتًا."
        }
    }

    private var authenticationCouldNotCompleteText: String {

        switch localization.language {

        case .hebrew:
            return "לא ניתן היה להשלים את האימות."

        case .english:
            return "Authentication could not be completed."

        case .arabic:
            return "تعذر إكمال التحقق."
        }
    }
}