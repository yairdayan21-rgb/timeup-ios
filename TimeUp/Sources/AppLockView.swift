import SwiftUI
import LocalAuthentication

struct AppLockView: View {

    let member: TimeUpMember

    @ObservedObject private var store =
        TimeUpStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @State private var isUnlocked = false

    @State private var isAuthenticating = false

    @State private var authenticationMessage = ""

    var body: some View {

        Group {

            if !store.isAppLockEnabled {

                authenticatedDestination

            } else if isUnlocked {

                authenticatedDestination

            } else {

                lockedView
            }
        }
        .onAppear {

            guard store.isAppLockEnabled else {
                return
            }

            guard !isUnlocked else {
                return
            }

            authenticate()
        }
    }

    // MARK: - Destination

    @ViewBuilder
    private var authenticatedDestination: some View {

        switch member.role {

        case .admin:

            AdminHomeView()

        case .member:

            MemberTabView()
        }
    }

    // MARK: - Locked View

    private var lockedView: some View {

        VStack(spacing: 24) {

            Spacer()

            Image(
                systemName: "faceid"
            )
            .font(
                .system(size: 72)
            )

            Text("TimeUp")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(authenticationRequiredText)
                .font(.headline)
                .multilineTextAlignment(
                    .center
                )

            if !authenticationMessage.isEmpty {

                Text(
                    authenticationMessage
                )
                .font(.subheadline)
                .multilineTextAlignment(
                    .center
                )
                .foregroundStyle(
                    .secondary
                )
                .padding(.horizontal)
            }

            Button {

                authenticate()

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
                            : unlockWithFaceIDText
                    )
                }
                .frame(
                    maxWidth: .infinity
                )
                .padding()
            }
            .buttonStyle(
                .borderedProminent
            )
            .disabled(
                isAuthenticating
            )
            .padding(
                .horizontal,
                32
            )

            Spacer()
        }
    }

    // MARK: - Authentication

    private func authenticate() {

        guard store.isAppLockEnabled else {

            isUnlocked = true

            return
        }

        guard !isAuthenticating else {
            return
        }

        isAuthenticating = true

        authenticationMessage = ""

        let context = LAContext()

        context.localizedCancelTitle =
            cancelText

        var error: NSError?

        guard
            context.canEvaluatePolicy(
                .deviceOwnerAuthentication,
                error: &error
            )
        else {

            isAuthenticating = false

            authenticationMessage =
                deviceAuthenticationUnavailableText

            return
        }

        let reason =
            authenticationReasonText

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) {
            success,
            authenticationError in

            DispatchQueue.main.async {

                isAuthenticating = false

                if success {

                    isUnlocked = true

                    authenticationMessage = ""

                } else {

                    isUnlocked = false

                    if let authenticationError =
                        authenticationError as? LAError {

                        switch authenticationError.code {

                        case .userCancel,
                             .systemCancel,
                             .appCancel:

                            authenticationMessage =
                                authenticationCancelledText

                        case .authenticationFailed:

                            authenticationMessage =
                                authenticationFailedText

                        case .biometryLockout:

                            authenticationMessage =
                                biometryLockoutText

                        default:

                            authenticationMessage =
                                authenticationCouldNotCompleteText
                        }

                    } else {

                        authenticationMessage =
                            authenticationCouldNotCompleteText
                    }
                }
            }
        }
    }

    // MARK: - Localization

    private var authenticationRequiredText: String {

        switch localization.language {

        case .hebrew:
            return "יש לאמת את הזהות כדי להיכנס"

        case .english:
            return "Authentication is required to continue"

        case .arabic:
            return "يجب التحقق من هويتك للمتابعة"
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

    private var unlockWithFaceIDText: String {

        switch localization.language {

        case .hebrew:
            return "פתיחה עם Face ID"

        case .english:
            return "Unlock with Face ID"

        case .arabic:
            return "فتح باستخدام Face ID"
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

    private var authenticationReasonText: String {

        switch localization.language {

        case .hebrew:
            return "אימות זהות לצורך כניסה ל-TimeUp"

        case .english:
            return "Authenticate to access TimeUp"

        case .arabic:
            return "تحقق من هويتك للدخول إلى TimeUp"
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
            return "האימות בוטל."

        case .english:
            return "Authentication was cancelled."

        case .arabic:
            return "تم إلغاء التحقق."
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

    private var biometryLockoutText: String {

        switch localization.language {

        case .hebrew:
            return "Face ID נעול זמנית. ניתן להשתמש בקוד המכשיר."

        case .english:
            return "Face ID is temporarily locked. You can use your device passcode."

        case .arabic:
            return "تم قفل Face ID مؤقتًا. يمكنك استخدام رمز دخول الجهاز."
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