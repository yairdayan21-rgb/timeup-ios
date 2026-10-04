import SwiftUI
import AuthenticationServices
import CryptoKit
import Security
import Supabase

struct LoginView: View {

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @State private var showJoinScreen = false
    @State private var showMemberApp = false
    @State private var showAdminApp = false

    @State private var appleSignInError = ""

    @State private var authenticatedProvider:
        TimeUpAuthProvider?

    @State private var authenticatedUserID:
        String?

    @State private var currentNonce:
        String?

    private struct SupabaseTimeUpUser: Codable {

        let id: UUID
        let authUserID: UUID
        let email: String?
        let displayName: String?
        let role: String

        enum CodingKeys: String, CodingKey {
            case id
            case authUserID = "auth_user_id"
            case email
            case displayName = "display_name"
            case role
        }
    }

    private struct NewSupabaseTimeUpUser: Encodable {

        let authUserID: UUID
        let email: String?
        let displayName: String?
        let role: String

        enum CodingKeys: String, CodingKey {
            case authUserID = "auth_user_id"
            case email
            case displayName = "display_name"
            case role
        }
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

            .navigationDestination(
                isPresented: $showJoinScreen
            ) {

                JoinGroupView(
                    authProvider:
                        authenticatedProvider,
                    externalUserID:
                        authenticatedUserID
                )
                .navigationBarBackButtonHidden(
                    true
                )
            }

            .navigationDestination(
                isPresented: $showMemberApp
            ) {

                MemberTabView()
                    .navigationBarBackButtonHidden(
                        true
                    )
            }

            .navigationDestination(
                isPresented: $showAdminApp
            ) {

                AdminHomeView()
                    .navigationBarBackButtonHidden(
                        true
                    )
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

                    let session =
                        try await
                            SupabaseManager.shared
                                .client
                                .auth
                                .signInWithIdToken(
                                    credentials:
                                        OpenIDConnectCredentials(
                                            provider: .apple,
                                            idToken: idToken,
                                            nonce: nonce
                                        )
                                )

                    let displayName =
                        appleDisplayName(
                            from: credential
                        )

                    try await
                        ensureSupabaseUserExists(
                            authUserID:
                                session.user.id,
                            email:
                                credential.email,
                            displayName:
                                displayName
                        )

                    await dataStore
                        .loadCurrentAccount()

                    await MainActor.run {

                        currentNonce = nil

                        authenticatedProvider =
                            .apple

                        authenticatedUserID =
                            appleUserID

                        routeAuthenticatedUser()
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

    // MARK: - Supabase User

    private func ensureSupabaseUserExists(
        authUserID: UUID,
        email: String?,
        displayName: String?
    ) async throws {

        let existingUsers:
            [SupabaseTimeUpUser] =
            try await
                SupabaseManager.shared.client
                    .from("users")
                    .select()
                    .eq(
                        "auth_user_id",
                        value:
                            authUserID.uuidString
                    )
                    .limit(1)
                    .execute()
                    .value

        if !existingUsers.isEmpty {
            return
        }

        let newUser =
            NewSupabaseTimeUpUser(
                authUserID:
                    authUserID,
                email:
                    email,
                displayName:
                    displayName,
                role:
                    "member"
            )

        try await
            SupabaseManager.shared.client
                .from("users")
                .insert(newUser)
                .execute()
    }

    private func routeAuthenticatedUser() {

        guard dataStore.currentUser != nil else {

            appleSignInError =
                "לא ניתן היה לטעון את חשבון TimeUp."

            return
        }

        if dataStore.isAdmin {

            showAdminApp = true
            return
        }

        if dataStore.hasActiveGroup {

            showMemberApp = true
            return
        }

        showJoinScreen = true
    }

    private func appleDisplayName(
        from credential:
            ASAuthorizationAppleIDCredential
    ) -> String? {

        guard
            let fullName =
                credential.fullName
        else {
            return nil
        }

        let formatter =
            PersonNameComponentsFormatter()

        let name =
            formatter.string(
                from: fullName
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return name.isEmpty
            ? nil
            : name
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
