import SwiftUI
import AuthenticationServices
import CryptoKit
import Security
import Supabase

struct LoginView: View {

    @StateObject private var store = TimeUpStore.shared

    @State private var showJoinScreen = false
    @State private var existingMemberDestination:
        ExistingMemberDestination?

    @State private var appleSignInError = ""

    @State private var authenticatedProvider:
        TimeUpAuthProvider?

    @State private var authenticatedUserID:
        String?

    @State private var currentNonce:
        String?

    private enum ExistingMemberDestination:
        Hashable {
        case admin(UUID)
        case member(UUID)
    }

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

            // MARK: New Apple account

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

            // MARK: Existing account

            .navigationDestination(
                item: $existingMemberDestination
            ) { destination in

                switch destination {

                case .admin:

                    AdminHomeView()
                        .navigationBarBackButtonHidden(
                            true
                        )

                case .member(let memberID):

                    if let member =
                        store.member(
                            id: memberID
                        )
                    {

                        MemberHomeView(
                            member: member
                        )
                        .navigationBarBackButtonHidden(
                            true
                        )

                    } else {

                        ContentUnavailableView(
                            "לא ניתן לפתוח את המשתמש",
                            systemImage:
                                "person.crop.circle.badge.exclamationmark"
                        )
                    }
                }
            }
        }
    }

    // MARK: - Sign in with Apple

    private func configureAppleRequest(
        _ request:
            ASAuthorizationAppleIDRequest
    ) {

        let nonce = randomNonceString()

        currentNonce = nonce

        request.requestedScopes = [
            .fullName,
            .email
        ]

        request.nonce = sha256(nonce)
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

            guard
                let nonce = currentNonce
            else {

                appleSignInError =
                    "לא ניתן היה לאמת את ההתחברות עם Apple."

                return
            }

            guard
                let identityToken =
                    credential.identityToken,
                let idToken =
                    String(
                        data: identityToken,
                        encoding: .utf8
                    )
            else {

                appleSignInError =
                    "לא התקבל Apple ID Token."

                return
            }

            let appleUserID =
                credential.user

            guard !appleUserID.isEmpty else {

                appleSignInError =
                    "לא התקבל מזהה משתמש מ-Apple."

                return
            }

            appleSignInError = ""

            Task {

                do {

                    _ = try await
                        SupabaseManager.shared.client.auth
                            .signInWithIdToken(
                                credentials:
                                    OpenIDConnectCredentials(
                                        provider: .apple,
                                        idToken: idToken,
                                        nonce: nonce
                                    )
                            )

                    await MainActor.run {

                        currentNonce = nil

                        continueAfterAppleSignIn(
                            appleUserID:
                                appleUserID
                        )
                    }

                } catch {

                    await MainActor.run {

                        currentNonce = nil

                        appleSignInError =
                            "ההתחברות ל-TimeUp לא הושלמה."
                    }
                }
            }

        case .failure(let error):

            currentNonce = nil
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

    private func continueAfterAppleSignIn(
        appleUserID: String
    ) {

        // בשלב זה כבר קיימת התחברות אמיתית
        // ל-Supabase Auth.

        if let existingMember =
            store.member(
                authProvider: .apple,
                externalUserID:
                    appleUserID
            )
        {

            store.setCurrentMember(
                existingMember
            )

            switch existingMember.role {

            case .admin:

                existingMemberDestination =
                    .admin(
                        existingMember.id
                    )

            case .member:

                existingMemberDestination =
                    .member(
                        existingMember.id
                    )
            }

            return
        }

        authenticatedProvider =
            .apple

        authenticatedUserID =
            appleUserID

        showJoinScreen = true
    }

    // MARK: - Nonce

    private func randomNonceString(
        length: Int = 32
    ) -> String {

        precondition(length > 0)

        let charset:
            [Character] =
            Array(
                "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
            )

        var result = ""
        var remainingLength = length

        while remainingLength > 0 {

            var random: UInt8 = 0

            let errorCode =
                SecRandomCopyBytes(
                    kSecRandomDefault,
                    1,
                    &random
                )

            if errorCode != errSecSuccess {
                fatalError(
                    "Unable to generate nonce."
                )
            }

            if random < charset.count {

                result.append(
                    charset[
                        Int(random)
                    ]
                )

                remainingLength -= 1
            }
        }

        return result
    }

    private func sha256(
        _ input: String
    ) -> String {

        let inputData =
            Data(input.utf8)

        let hashed =
            SHA256.hash(
                data: inputData
            )

        return hashed.map {
            String(
                format: "%02x",
                $0
            )
        }
        .joined()
    }

    // MARK: - Google

    private func startGoogleSignIn() {

        authenticatedProvider = nil
        authenticatedUserID = nil

        appleSignInError =
            "Google Sign-In עדיין לא מחובר."
    }
}
