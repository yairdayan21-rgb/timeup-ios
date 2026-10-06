import SwiftUI

@MainActor
final class MemberOnboardingCoordinator:
    ObservableObject {

    static let shared =
        MemberOnboardingCoordinator()

    enum PresentationMode:
        Equatable {

        case firstTime
        case replay
    }

    @Published private(set)
    var isPresented = false

    @Published private(set)
    var presentationMode:
        PresentationMode = .firstTime

    private init() {}

    // MARK: - First Time

    func presentFirstTimeIfNeeded(
        user:
            SupabaseDataStore.TimeUpRemoteUser
    ) {

        guard !isPresented else {
            return
        }

        guard user.role
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased() == "member"
        else {
            return
        }

        guard !user.onboardingCompleted else {
            return
        }

        presentationMode = .firstTime
        isPresented = true
    }

    // MARK: - Replay

    func presentReplay() {

        guard !isPresented else {
            return
        }

        presentationMode = .replay
        isPresented = true
    }

    // MARK: - Dismiss

    func dismiss() {

        isPresented = false
    }

    // MARK: - Tour Mode

    var tourMode:
        MemberOnboardingTour.Mode {

        switch presentationMode {

        case .firstTime:
            return .firstTime

        case .replay:
            return .replay
        }
    }

    // MARK: - Finish

    func finish(
        dataStore: SupabaseDataStore
    ) async {

        switch presentationMode {

        case .firstTime:

            await dataStore
                .completeOnboarding()

            guard
                dataStore.currentUser?
                    .onboardingCompleted == true
            else {
                return
            }

            dismiss()

        case .replay:

            dismiss()
        }
    }

    // MARK: - Goal Method

    func goalMethod(
        from dataStore:
            SupabaseDataStore
    ) -> String {

        dataStore
            .activeMemberGroup?
            .goalMethod
            ?? ""
    }
}