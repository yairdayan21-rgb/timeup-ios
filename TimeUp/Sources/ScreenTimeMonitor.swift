import Foundation
import DeviceActivity

final class ScreenTimeMonitor {
    static let shared = ScreenTimeMonitor()

    private let center = DeviceActivityCenter()
    private let activityName = DeviceActivityName("timeup.daily")

    private let sharedDefaults = UserDefaults(
        suiteName: "group.com.timeup.shared"
    )

    private init() {}

    // MARK: - Monitoring

    func startMonitoring(
        targetMinutes: Int? = nil
    ) throws {

        syncCompletedDayIfNeeded()

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(
                hour: 0,
                minute: 0
            ),
            intervalEnd: DateComponents(
                hour: 23,
                minute: 59
            ),
            repeats: true
        )

        let normalizedTarget =
            targetMinutes.map {
                max(1, $0)
            }

        var thresholds = Set<Int>()

        // בדיקה רגילה בערך כל 10 דקות שימוש.
        for minutes in stride(
            from: 10,
            through: 24 * 60,
            by: 10
        ) {
            thresholds.insert(minutes)
        }

        if let target = normalizedTarget {

            // בעשר הדקות האחרונות:
            // בדיקה כל שתי דקות.
            for minutes in stride(
                from: max(1, target - 10),
                through: target,
                by: 2
            ) {
                thresholds.insert(minutes)
            }

            // בחמש הדקות האחרונות:
            // בדיקה בכל דקה.
            for minutes in
                max(1, target - 5)...target
            {
                thresholds.insert(minutes)
            }
        }

        var events:
            [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        for minutes in thresholds.sorted() {

            let eventName =
                DeviceActivityEvent.Name(
                    "timeup.usage.\(minutes)"
                )

            events[eventName] =
                DeviceActivityEvent(
                    threshold: DateComponents(
                        minute: minutes
                    ),
                    includesPastActivity: true
                )
        }

        if let normalizedTarget {

            sharedDefaults?.set(
                normalizedTarget,
                forKey: "configuredDailyTargetMinutes"
            )

        } else {

            sharedDefaults?.removeObject(
                forKey: "configuredDailyTargetMinutes"
            )
        }

        try center.startMonitoring(
            activityName,
            during: schedule,
            events: events
        )
    }

    func startPrototypeMonitoring() throws {
        try startMonitoring()
    }

    func stopMonitoring() {
        center.stopMonitoring(
            [activityName]
        )
    }

    // MARK: - Completed Day Sync

    func syncCompletedDayIfNeeded() {

        guard
            let defaults = sharedDefaults,
            let completedDay = defaults.object(
                forKey: "lastCompletedDayDate"
            ) as? Date
        else {
            return
        }

        guard
            let member =
                TimeUpStore.shared.currentMember
        else {
            return
        }

        if TimeUpStore.shared.progress(
            for: member.id,
            on: completedDay
        ) != nil {

            markCompletedDayAsSynced(
                completedDay
            )

            return
        }

        let completedUsage =
            resolvedCompletedUsage(
                completedDay: completedDay,
                defaults: defaults
            )

        let isLearningDay =
            shouldBeLearningDay(
                memberID: member.id
            )

        TimeUpStore.shared.completeDay(
            for: member.id,
            usageMinutes: completedUsage,
            date: completedDay,
            isLearningDay: isLearningDay
        )

        markCompletedDayAsSynced(
            completedDay
        )
    }

    // MARK: - Completed Usage

    private func resolvedCompletedUsage(
        completedDay: Date,
        defaults: UserDefaults
    ) -> Int {

        let fallbackUsage =
            max(
                0,
                defaults.integer(
                    forKey: "lastCompletedDayUsageMinutes"
                )
            )

        guard
            let reportUpdatedAt =
                defaults.object(
                    forKey: "reportedUsageUpdatedAt"
                ) as? Date,
            Calendar.current.isDate(
                reportUpdatedAt,
                inSameDayAs: completedDay
            )
        else {
            return fallbackUsage
        }

        guard
            defaults.object(
                forKey: "reportedUsageMinutes"
            ) != nil
        else {
            return fallbackUsage
        }

        return max(
            0,
            defaults.integer(
                forKey: "reportedUsageMinutes"
            )
        )
    }

    // MARK: - Learning Day

    private func shouldBeLearningDay(
        memberID: UUID
    ) -> Bool {

        return TimeUpStore.shared
            .progress(for: memberID)
            .isEmpty
    }

    // MARK: - Sync State

    private func markCompletedDayAsSynced(
        _ date: Date
    ) {
        sharedDefaults?.set(
            date,
            forKey: "lastSyncedCompletedDayDate"
        )
    }
}
