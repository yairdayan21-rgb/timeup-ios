import SwiftUI
import LocalAuthentication

struct FaceIDSetupView: View {

    let member: TimeUpMember

    @ObservedObject private var store =
        TimeUpStore.shared

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

                Text("להגן על TimeUp?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(
                    "אפשר להשתמש ב-Face ID כדי להגן על הכניסה לחשבון שלך."
                )
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
                            ? "מאמת..."
                            : "הפעל Face ID"
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

                Text("לא עכשיו")
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

        let reason =
            "הפעלת הגנה על TimeUp"

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
                                "האימות בוטל. אפשר לנסות שוב או לבחור לא עכשיו."

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

                    } else {

                        errorMessage =
                            "לא ניתן היה להשלים את האימות."
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
}
