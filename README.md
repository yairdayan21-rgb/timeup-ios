# TimeUp iOS

TimeUp is an iPhone app for reducing screen time through a group challenge.

The group helps each member meet their target, and each member helps the group succeed.

## Technology

- SwiftUI.
- Supabase authentication and database.
- DeviceActivity and FamilyControls.
- Screen Time monitor and report extensions.
- XcodeGen.
- GitHub Actions build workflow.
- Minimum deployment target: iOS 17.4.

## Accounts and groups

- Admin and Member roles.
- Sign in with Apple integration.
- Google sign-in is currently a placeholder.
- Random, case-sensitive group codes containing eight English letters and digits.
- Server-side rate limiting for member join attempts.
- Reserved admin registration code `0000`, available when no registered admin owns it.
- Account deletion with admin choices for preserving or deleting groups.

## Goal methods

- Personal percentage: after group success, each member's next target is based on their actual usage that day minus the configured reduction.
- Group average percentage: after group success, all members receive a target based on the group's actual average usage minus the configured reduction, rounded up to a whole minute.
- Manual: each member's target remains fixed until the admin changes it.

When a group fails, percentage-based targets remain unchanged.

A learning day measures usage and provides the baseline for the first target. It does not count toward the group streak.

Supabase is responsible for group-day finalization. Missing data must remain pending rather than being treated as failure.

## Member experience

- Personal dashboard with usage, target and remaining screen time.
- Goal-method explanations.
- Screen-free alternatives and group activity feed.
- Progress comparisons based on recorded learning-day and completed-day data.
- Group overview, details, control panel and member list.
- Group chat with unread indicators and editable encouragement drafts.
- Group ranking.
- Profile and settings.
- Guided onboarding and tutorial replay.
- Hebrew, English and Arabic localization, with RTL support for Hebrew and Arabic.

## Validation status

Code compilation does not establish end-to-end readiness.

The MVP is complete only after successful end-to-end validation on two real iPhones.

Outstanding device and runtime checks include:

- Authentication and session restoration.
- Screen Time permissions, measurement and background reporting.
- Group chat and alternatives across devices.
- Group permissions, settings and manual targets.
- Account deletion and admin registration reuse.
- Onboarding completion and replay.
- Daily finalization, pending data, targets and streaks.

Building and running the iOS app requires macOS with Xcode.