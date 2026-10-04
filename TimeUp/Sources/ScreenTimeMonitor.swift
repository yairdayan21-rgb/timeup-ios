import Foundation
import DeviceActivity

final class ScreenTimeMonitor {

    static let shared = ScreenTimeMonitor()

    private let center =
        DeviceActivityCenter()

    private let activityName =
        DeviceActivityName(
            "timeup.daily"
        )

    private let sharedDefaults =
        UserDefaults(
            suiteName:
                "group.com.timeup.shared"
        )

    private init() {}

    // MARK: - Monitoring

    func startMonitoring(
        targetMinutes: Int? = nil
    ) throws {

        let schedule =
            DeviceActivitySchedule(
                intervalStart:
                    DateComponents(
                        hour: 0,
                        minute: 0
                    ),
                intervalEnd:
                    DateComponents(
                        hour: 23,
                        minute: 59
                    ),
                repeats: true
            )

        let normalizedTarget =
            targetMinutes.map {
                max(1, $0)
            }

        var thresholds =
            Set<Int>()

        // MARK: Normal monitoring
        //
        // During the normal part of the day,
        // DeviceActivity reports approximately
        // every 10 minutes of accumulated usage.

        for minutes in stride(
            from: 10,
            through: 24 * 60,
            by: 10
        ) {

            thresholds.insert(
                minutes
            )
        }

        if let target =
            normalizedTarget {

            // MARK: Last 10 minutes
            //
            // From 10 minutes before the target,
            // increase monitoring resolution
            // to approximately every 2 minutes.

            for minutes in stride(
                from:
                    max(
                        1,
                        target - 10
                    ),
                through: target,
                by: 2
            ) {

                thresholds.insert(
                    minutes
                )
            }

            // MARK: Last 5 minutes
            //
            // From 5 minutes before the target,
            // monitor every minute.

            for minutes in
                max(
                    1,
                    target - 5
                )...target {

                thresholds.insert(
                    minutes
                )
            }
        }

        var events:
            [
                DeviceActivityEvent.Name:
                    DeviceActivityEvent
            ] = [:]

        for minutes in
            thresholds.sorted() {

            let eventName =
                DeviceActivityEvent.Name(
                    "timeup.usage.\(minutes)"
                )

            events[eventName] =
                DeviceActivityEvent(
                    threshold:
                        DateComponents(
                            minute: minutes
                        ),
                    includesPastActivity:
                        true
                )
        }

        // Save today's configured target
        // in the shared App Group so the
        // DeviceActivityMonitor extension
        // can calculate remaining minutes
        // and send the warning notification.

        if let normalizedTarget {

            sharedDefaults?.set(
                normalizedTarget,
                forKey:
                    "configuredDailyTargetMinutes"
            )

        } else {

            sharedDefaults?
                .removeObject(
                    forKey:
                        "configuredDailyTargetMinutes"
                )
        }

        try center.startMonitoring(
            activityName,
            during: schedule,
            events: events
        )
    }

    // MARK: - Prototype Monitoring

    func startPrototypeMonitoring()
        throws {

        try startMonitoring()
    }

    // MARK: - Stop Monitoring

    func stopMonitoring() {

        center.stopMonitoring(
            [activityName]
        )
    }
}
