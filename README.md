# TimeUp iOS

TimeUp iOS Screen Time POC.

## Current development status

The prototype currently includes:

- Login screen with Apple/Google demo entry points.
- Admin demo entry through code `0000`.
- Group creation with goal method, reduction percentage and success-day settings.
- Persistent local storage for groups and group members.
- Group-code based member joining.
- Member home screen.
- Screen Time authorization entry point for members.
- Device Activity monitor extension and shared App Group storage.
- Admin group details showing persisted members.
- XcodeGen configuration targeting iOS 17.4.
- UI tests for login and basic join flows.
- GitHub Actions build and UI-test workflow.

## Important limitation

The current persistence is local to the device. Cross-device synchronization, real authentication, server/database storage, daily goal calculations, streak logic, analytics and AI are not implemented yet.

Build and XCTest verification require macOS with Xcode and an iOS Simulator. The repository CI is configured to perform these checks on GitHub Actions.

## Next development focus

1. Validate the generated Xcode project and CI build.
2. Implement the real daily Screen Time measurement and goal engine.
3. Persist daily progress and streaks.
4. Add a real shared backend for groups and memberships.
5. Connect admin analytics to real member data.
