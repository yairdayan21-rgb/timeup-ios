import SwiftUI
import LocalAuthentication

struct PersonalSettingsView: View {

    @ObservedObject private var store =
        TimeUpStore.shared

    @State private var isAuthenticating = false
    @State private var errorMessage = ""

    var body: some View {

        Form {

            Section {

                Toggle(
                    "נעילת TimeUp עם Face ID",
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
                .disabled(isAuthenticating)

            } header: {

                Text("אבטחה")

            } footer: {

                Text(
                    "כאשר ההגנה פעילה, TimeUp יבקש אימות כדי להגן על החשבון."
                )
            }

            if isAuthenticating {

                Section {

                    HStack {

                        ProgressView()

                        Text("מאמת...")
                            .foregroundStyle(
                                .secondary
                            )
                    }
                }
            }

            if !errorMessage.isEmpty {

                Section {

                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("הגדרות")
        .navigationBarTitleDisplayMode(
            .inline
        )
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
                "הפעלת הגנת Face ID על TimeUp"
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
                "אימות לצורך ביטול הגנת Face ID"
        ) {

            store.setAppLockEnabled(
                false
            )
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

        let context = LAContext()

        context.localizedCancelTitle =
            "ביטול"

        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &error
        ) else {

            isAuthenticating = false

            errorMessage =
                "לא ניתן להשתמש באימות המכשיר כרגע."

            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) {
            success,
            authenticationError in

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

    // MARK: - Error

    private func handleAuthenticationError(
        _ error: Error?
    ) {

        guard let authenticationError =
            error as? LAError
        else {

            errorMessage =
                "לא ניתן היה להשלים את האימות."

            return
        }

        switch authenticationError.code {

        case .userCancel,
             .systemCancel,
             .appCancel:

            errorMessage =
                "האימות בוטל."

        case .authenticationFailed:

            errorMessage =
                "האימות לא הצליח. נסה שוב."

        case .biometryNotAvailable:

            errorMessage =
                "Face ID אינו זמין במכשיר הזה."

        case .biometryNotEnrolled:

            errorMessage =
                "לא הוגדר Face ID במכשיר."

        case .biometryLockout:

            errorMessage =
                "Face ID נעול זמנית."

        default:

            errorMessage =
                "לא ניתן היה להשלים את האימות."
        }
    }
}
