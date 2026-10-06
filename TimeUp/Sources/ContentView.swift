import SwiftUI
import FamilyControls

struct ContentView: View {

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @State private var status: ScreenTimeStatus =
        .checking

    @State private var monitorEvent: MonitorEvent =
        .none

    private let sharedDefaults = UserDefaults(
        suiteName: "group.com.timeup.shared"
    )

    var body: some View {

        VStack(spacing: 24) {

            Image(systemName: "hourglass")
                .font(.system(size: 60))

            Text("TimeUp")
                .font(.largeTitle)
                .bold()

            Text(statusText)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(thresholdText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(connectScreenTimeText) {

                Task {

                    do {

                        try await AuthorizationCenter.shared
                            .requestAuthorization(
                                for: .individual
                            )

                        checkAuthorization()

                    } catch {

                        checkAuthorization()
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            Button(refreshStatusText) {

                readMonitorData()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .onAppear {

            checkAuthorization()

            readMonitorData()
        }
    }

    // MARK: - Authorization

    private func checkAuthorization() {

        switch AuthorizationCenter.shared.authorizationStatus {

        case .approved,
             .approvedWithDataAccess:

            do {

                try ScreenTimeMonitor.shared
                    .startPrototypeMonitoring()

                status = .connected

            } catch {

                status = .monitoringFailed
            }

        case .denied:

            status = .denied

        case .notDetermined:

            status = .notConnected

        @unknown default:

            status = .unknown
        }
    }

    // MARK: - Monitor Data

    private func readMonitorData() {

        guard let date = sharedDefaults?.object(
            forKey: "lastThresholdReachedAt"
        ) as? Date else {

            monitorEvent = .none

            return
        }

        let eventName = sharedDefaults?.string(
            forKey: "lastThresholdEventName"
        ) ?? unknownEventText

        monitorEvent = .received(
            name: eventName,
            date: date
        )
    }

    // MARK: - Status

    private enum ScreenTimeStatus {

        case checking
        case connected
        case monitoringFailed
        case denied
        case notConnected
        case unknown
    }

    private enum MonitorEvent {

        case none

        case received(
            name: String,
            date: Date
        )
    }

    // MARK: - Localized Status

    private var statusText: String {

        switch status {

        case .checking:

            switch localization.language {

            case .hebrew:
                return "בודק את חיבור זמן המסך..."

            case .english:
                return "Checking Screen Time..."

            case .arabic:
                return "جارٍ التحقق من وقت الشاشة..."
            }

        case .connected:

            switch localization.language {

            case .hebrew:
                return "זמן המסך מחובר ✓"

            case .english:
                return "Screen Time connected ✓"

            case .arabic:
                return "تم ربط وقت الشاشة ✓"
            }

        case .monitoringFailed:

            switch localization.language {

            case .hebrew:
                return "זמן המסך מחובר — הפעלת הניטור נכשלה"

            case .english:
                return "Screen Time connected — monitoring failed"

            case .arabic:
                return "تم ربط وقت الشاشة — فشل تشغيل المراقبة"
            }

        case .denied:

            switch localization.language {

            case .hebrew:
                return "הגישה לזמן המסך נדחתה"

            case .english:
                return "Screen Time access denied"

            case .arabic:
                return "تم رفض الوصول إلى وقت الشاشة"
            }

        case .notConnected:

            switch localization.language {

            case .hebrew:
                return "זמן המסך אינו מחובר"

            case .english:
                return "Screen Time is not connected"

            case .arabic:
                return "وقت الشاشة غير متصل"
            }

        case .unknown:

            switch localization.language {

            case .hebrew:
                return "סטטוס ההרשאה אינו ידוע"

            case .english:
                return "Unknown authorization status"

            case .arabic:
                return "حالة الإذن غير معروفة"
            }
        }
    }

    // MARK: - Localized Monitor Event

    private var thresholdText: String {

        switch monitorEvent {

        case .none:

            switch localization.language {

            case .hebrew:
                return "עדיין לא התקבל אירוע זמן מסך"

            case .english:
                return "No Screen Time event received yet"

            case .arabic:
                return "لم يتم استلام حدث وقت شاشة بعد"
            }

        case let .received(name, date):

            let formattedDate =
                localizedDate(date)

            switch localization.language {

            case .hebrew:
                return """
                התקבל אירוע זמן מסך ✓
                \(name)
                \(formattedDate)
                """

            case .english:
                return """
                Screen Time event received ✓
                \(name)
                \(formattedDate)
                """

            case .arabic:
                return """
                تم استلام حدث وقت شاشة ✓
                \(name)
                \(formattedDate)
                """
            }
        }
    }

    // MARK: - Buttons

    private var connectScreenTimeText: String {

        switch localization.language {

        case .hebrew:
            return "חיבור זמן מסך"

        case .english:
            return "Connect Screen Time"

        case .arabic:
            return "ربط وقت الشاشة"
        }
    }

    private var refreshStatusText: String {

        switch localization.language {

        case .hebrew:
            return "רענון סטטוס זמן המסך"

        case .english:
            return "Refresh Screen Time Status"

        case .arabic:
            return "تحديث حالة وقت الشاشة"
        }
    }

    private var unknownEventText: String {

        switch localization.language {

        case .hebrew:
            return "אירוע לא ידוע"

        case .english:
            return "Unknown event"

        case .arabic:
            return "حدث غير معروف"
        }
    }

    // MARK: - Date Formatting

    private func localizedDate(
        _ date: Date
    ) -> String {

        let formatter =
            DateFormatter()

        formatter.locale =
            localization.language.locale

        formatter.dateStyle =
            .medium

        formatter.timeStyle =
            .medium

        return formatter.string(
            from: date
        )
    }
}