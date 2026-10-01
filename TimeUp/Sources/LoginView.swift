import SwiftUI

struct LoginView: View {
    @State private var showJoinScreen = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                Spacer()

                Image(systemName: "hourglass")
                    .font(.system(size: 64, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.primary)

                Text("TimeUp")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .padding(.top, 20)

                Text("להקטין זמן מסך. לגדול ביחד.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                Spacer()

                VStack(spacing: 12) {

                    Button {
                        showJoinScreen = true
                    } label: {
                        HStack {
                            Image(systemName: "apple.logo")

                            Text("Continue with Apple")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                    .foregroundStyle(Color(.systemBackground))

                    Button {
                        showJoinScreen = true
                    } label: {
                        HStack {
                            Image(systemName: "g.circle.fill")

                            Text("Continue with Google")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                    }
                    .buttonStyle(.bordered)
                }

                Text("By continuing, you agree to TimeUp's Terms & Privacy Policy.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                Spacer()
                    .frame(height: 32)
            }
            .padding(.horizontal, 24)
            .navigationDestination(isPresented: $showJoinScreen) {
                JoinGroupView()
            }
        }
    }
}
