import SwiftUI
import AuthenticationServices

struct LoginView: View {

    @State private var showJoinScreen = false
    @State private var appleSignInError = ""

    @State private var authenticatedProvider:
        TimeUpAuthProvider?

    @State private var authenticatedUserID:
        String?

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                Spacer()

                Image(systemName: "hourglass")
                    .font(
                        .system(
                            size: 64,
                            weight: .light
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.primary)

                Text("TimeUp")
                    .font(
                        .system(
                            size: 40,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .padding(.top, 20)

                Text("להקטין זמן מסך. לגדול ביחד.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                Spacer()

                VStack(spacing: 12) {

                    SignInWithAppleButton(
                        .continue,
                        onRequest:
                            configureAppleRequest,
                        onCompletion:
                            handleAppleResult
                    )
                    .signInWithAppleButtonStyle(
                        .black
                    )
                    .frame(height: 54)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 12
                        )
                    )

                    Button {
                        startGoogleSignIn()
                    } label: {

                        HStack {

                            Image(
                                systemName:
                                    "g.circle.fill"
                            )

                            Text(
                                "Continue with Google"
                            )
                            .fontWeight(.semibold)
                        }
                        .frame(
                            maxWidth: .infinity
                        )
                        .frame(height: 54)
                    }
                    .buttonStyle(.bordered)
                }

                if !appleSignInError.isEmpty {

                    Text(appleSignInError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(
                            .center
                        )
                        .padding(.top, 12)
                }

                Text(
                    "By continuing, you agree to TimeUp's Terms & Privacy Policy."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 20)

                Spacer()
                    .frame(height: 32)
            }
            .padding(.horizontal, 24)
            .navigationDestination(
                isPresented: $showJoinScreen
            ) {

                JoinGroupView(
                    authProvider:
                        authenticatedProvider,
                    externalUserID:
                        authenticatedUserID
                )
            }
        }
    }

    // MARK: - Sign in with Apple

    private func configureAppleRequest(
        _ request:
            ASAuthorizationAppleIDRequest
    ) {

        request.requestedScopes = [
            .fullName,
            .email
        ]
    }

    private func handleAppleResult(
        _ result: Result<
            ASAuthorization,
            Error
        >
    ) {

        switch result {

        case .success(let authorization):

            guard
                let credential =
                    authorization.credential
                        as?
                        ASAuthorizationAppleIDCredential
            else {

                appleSignInError =
                    "לא ניתן היה לקרוא את פרטי ההתחברות."

                return
            }

            let appleUserID =
                credential.user

            guard !appleUserID.isEmpty else {

                appleSignInError =
                    "לא התקבל מזהה משתמש מ-Apple."

                return
            }

            authenticatedProvider =
                .apple

            authenticatedUserID =
                appleUserID

            appleSignInError = ""

            showJoinScreen = true

        case .failure(let error):

            authenticatedProvider = nil
            authenticatedUserID = nil

            if
                let authorizationError =
                    error as?
                    ASAuthorizationError,
                authorizationError.code
                    == .canceled
            {

                appleSignInError = ""

            } else {

                appleSignInError =
                    "ההתחברות עם Apple לא הושלמה."
            }
        }
    }

    // MARK: - Google

    private func startGoogleSignIn() {

        authenticatedProvider = nil
        authenticatedUserID = nil

        appleSignInError =
            "Google Sign-In עדיין לא מחובר."
    }
}
