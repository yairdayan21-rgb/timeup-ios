import SwiftUI
import LocalAuthentication

struct AppLockView: View {

    let member: TimeUpMember

    @State private var isUnlocked = false
    @State private var isAuthenticating = false
    @State private var authenticationMessage = ""

    var body: some View {
        Group {

            if isUnlocked {

                authenticatedDestination

            } else {

                lockedView
            }
        }
        .onAppear {
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

            MemberHomeView(
                member: member
            )
        }
    }

    // MARK: - Locked Screen

    private var lockedView: some View {

        VStack(spacing: 24) {

            Spacer()

            Image(systemName: "faceid")
                .font(.system(size: 72))

            Text("TimeUp")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("יש לאמת את הזהות כדי להיכנס")
                .font(.headline)
                .multilineTextAlignment(.center)

            if !authenticationMessage.isEmpty {

                Text(authenticationMessage)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            Button {
                authenticate()
            } label: {

                HStack {

                    if isAuthenticating {

                        ProgressView()

                    } else {

                        Image(systemName: "faceid")
                    }

                    Text(
                        isAuthenticating
                        ? "מאמת..."
                        : "פתיחה עם Face ID"
                    )
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isAuthenticating)
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Authentication

    private func authenticate() {

        guard !isAuthenticating else {
            return
        }

        isAuthenticating = true
        authenticationMessage = ""

        let context = LAContext()

        context.localizedCancelTitle = "ביטול"

        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &error
        ) else {

            isAuthenticating = false

            authenticationMessage =
                "לא ניתן להשתמש באימות המכשיר כרגע."

            return
        }

        let reason =
            "אימות זהות לצורך כניסה ל-TimeUp"

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) { success, authenticationError in

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
                                "האימות בוטל."

                        case .authenticationFailed:

                            authenticationMessage =
                                "האימות לא הצליח. נסה שוב."

                        case .biometryLockout:

                            authenticationMessage =
                                "Face ID נעול זמנית. ניתן להשתמש בקוד המכשיר."

                        default:

                            authenticationMessage =
                                "לא ניתן היה להשלים את האימות."
                        }

                    } else {

                        authenticationMessage =
                            "לא ניתן היה להשלים את האימות."
                    }
                }
            }
        }
    }
}
