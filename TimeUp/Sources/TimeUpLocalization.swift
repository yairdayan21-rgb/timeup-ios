import SwiftUI
import Foundation
import Combine

// MARK: - Supported Language

enum TimeUpLanguage: String, CaseIterable, Identifiable, Codable {

    case hebrew = "he"
    case english = "en"
    case arabic = "ar"

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .hebrew:
            return "עברית"
        case .english:
            return "English"
        case .arabic:
            return "العربية"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var layoutDirection: LayoutDirection {
        switch self {
        case .hebrew, .arabic:
            return .rightToLeft
        case .english:
            return .leftToRight
        }
    }
}

// MARK: - Localization Manager

@MainActor
final class TimeUpLocalization: ObservableObject {

    static let shared = TimeUpLocalization()

    private static let languageKey =
        "timeup.preferredLanguage"

    @Published private(set) var language: TimeUpLanguage

    private init() {
        if let savedValue = UserDefaults.standard.string(
            forKey: Self.languageKey
        ),
           let savedLanguage = TimeUpLanguage(
                rawValue: savedValue
           ) {
            language = savedLanguage
        } else {
            language = .hebrew
        }
    }

    func setLanguage(_ newLanguage: TimeUpLanguage) {
        guard language != newLanguage else {
            return
        }

        language = newLanguage

        UserDefaults.standard.set(
            newLanguage.rawValue,
            forKey: Self.languageKey
        )
    }

    func reset() {
        language = .hebrew

        UserDefaults.standard.removeObject(
            forKey: Self.languageKey
        )
    }

    // MARK: - Text

    func text(_ key: TimeUpText) -> String {
        key.value(language: language)
    }
}

// MARK: - Localized Text Keys

enum TimeUpText {

    // MARK: General

    case close
    case cancel
    case save
    case done
    case settings
    case profile
    case loading
    case refresh
    case error
    case retry

    // MARK: Navigation

    case dashboard
    case group
    case ranking

    // MARK: Dashboard

    case hello
    case connectedToTimeUp
    case myGroup
    case groupCode
    case myToday
    case usage
    case target
    case learningDay
    case achievedTarget
    case targetNotAchieved
    case dayInProgress

    // MARK: Group

    case groupStreak
    case days
    case groupStatusToday
    case completed
    case average
    case groupAchievedTarget
    case groupStillInProgress
    case groupResultPending
    case members
    case loadingGroup
    case noMembers
    case you
    case joined

    // MARK: Ranking

    case groupRanking
    case loadingRanking
    case noRanking
    case rankingWillAppear
    case myGroupBadge

    // MARK: Alternatives

    case alternativesTitle
    case alternativesSubtitle
    case loadingAlternatives
    case alternativesFinished
    case alternativesTomorrow
    case groupActivityToday
    case loadingGroupActivity
    case noAlternativeCompleted
    case beFirstInGroup

    // MARK: Account

    case logout
    case accountLoading
    case accountUnavailable
    case tryLoginAgain

    // MARK: Language

    case language
    case hebrew
    case english
    case arabic

    func value(language: TimeUpLanguage) -> String {
        switch language {

        // MARK: Hebrew

        case .hebrew:
            switch self {
            case .close:
                return "סגור"

            case .cancel:
                return "ביטול"

            case .save:
                return "שמור"

            case .done:
                return "סיום"

            case .settings:
                return "הגדרות"

            case .profile:
                return "פרופיל"

            case .loading:
                return "טוען..."

            case .refresh:
                return "רענון"

            case .error:
                return "שגיאה"

            case .retry:
                return "נסה שוב"

            case .dashboard:
                return "דשבורד"

            case .group:
                return "הקבוצה"

            case .ranking:
                return "דירוג"

            case .hello:
                return "שלום"

            case .connectedToTimeUp:
                return "הנתונים שלך מחוברים ל-TimeUp"

            case .myGroup:
                return "הקבוצה שלי"

            case .groupCode:
                return "קוד קבוצה"

            case .myToday:
                return "היום שלי"

            case .usage:
                return "שימוש"

            case .target:
                return "יעד"

            case .learningDay:
                return "יום למידה"

            case .achievedTarget:
                return "עמדת ביעד"

            case .targetNotAchieved:
                return "היעד לא הושג"

            case .dayInProgress:
                return "היום עדיין בתהליך"

            case .groupStreak:
                return "רצף קבוצתי"

            case .days:
                return "ימים"

            case .groupStatusToday:
                return "מצב הקבוצה היום"

            case .completed:
                return "השלימו"

            case .average:
                return "ממוצע"

            case .groupAchievedTarget:
                return "הקבוצה עמדה ביעד"

            case .groupStillInProgress:
                return "הקבוצה עדיין לא השלימה את היעד"

            case .groupResultPending:
                return "התוצאה הקבוצתית של היום עדיין לא נקבעה."

            case .members:
                return "חברים"

            case .loadingGroup:
                return "טוען נתוני קבוצה..."

            case .noMembers:
                return "אין חברים להצגה"

            case .you:
                return "אתה"

            case .joined:
                return "הצטרף"

            case .groupRanking:
                return "דירוג קבוצות"

            case .loadingRanking:
                return "טוען דירוג קבוצות..."

            case .noRanking:
                return "אין עדיין דירוג"

            case .rankingWillAppear:
                return "הדירוג יופיע כאשר יהיו נתונים לקבוצות."

            case .myGroupBadge:
                return "הקבוצה שלי"

            case .alternativesTitle:
                return "אלטרנטיבות לשימושכם"

            case .alternativesSubtitle:
                return "עשיתם? סימנתם ✓"

            case .loadingAlternatives:
                return "מגריל לכם רעיונות להיום..."

            case .alternativesFinished:
                return "סיימתם את ההצעות להיום"

            case .alternativesTomorrow:
                return "מחר יחכו לכם רעיונות חדשים."

            case .groupActivityToday:
                return "מה הקבוצה עשתה היום"

            case .loadingGroupActivity:
                return "טוען פעילות קבוצתית..."

            case .noAlternativeCompleted:
                return "עוד לא סומנה אלטרנטיבה היום."

            case .beFirstInGroup:
                return "תהיו הראשונים בקבוצה שעושים משהו במקום להיות בטלפון."

            case .logout:
                return "יציאה מהחשבון"

            case .accountLoading:
                return "טוען את החשבון..."

            case .accountUnavailable:
                return "לא ניתן לטעון את החשבון"

            case .tryLoginAgain:
                return "נסה להתחבר מחדש."

            case .language:
                return "שפה"

            case .hebrew:
                return "עברית"

            case .english:
                return "אנגלית"

            case .arabic:
                return "ערבית"
            }

        // MARK: English

        case .english:
            switch self {
            case .close:
                return "Close"

            case .cancel:
                return "Cancel"

            case .save:
                return "Save"

            case .done:
                return "Done"

            case .settings:
                return "Settings"

            case .profile:
                return "Profile"

            case .loading:
                return "Loading..."

            case .refresh:
                return "Refresh"

            case .error:
                return "Error"

            case .retry:
                return "Try Again"

            case .dashboard:
                return "Dashboard"

            case .group:
                return "Group"

            case .ranking:
                return "Ranking"

            case .hello:
                return "Hello"

            case .connectedToTimeUp:
                return "Your data is connected to TimeUp"

            case .myGroup:
                return "My Group"

            case .groupCode:
                return "Group Code"

            case .myToday:
                return "My Day"

            case .usage:
                return "Usage"

            case .target:
                return "Target"

            case .learningDay:
                return "Learning Day"

            case .achievedTarget:
                return "Target Achieved"

            case .targetNotAchieved:
                return "Target Not Achieved"

            case .dayInProgress:
                return "Today is still in progress"

            case .groupStreak:
                return "Group Streak"

            case .days:
                return "days"

            case .groupStatusToday:
                return "Group Status Today"

            case .completed:
                return "Completed"

            case .average:
                return "Average"

            case .groupAchievedTarget:
                return "The group achieved today's target"

            case .groupStillInProgress:
                return "The group has not completed today's target yet"

            case .groupResultPending:
                return "Today's group result has not been determined yet."

            case .members:
                return "Members"

            case .loadingGroup:
                return "Loading group data..."

            case .noMembers:
                return "No members to display"

            case .you:
                return "You"

            case .joined:
                return "Joined"

            case .groupRanking:
                return "Group Ranking"

            case .loadingRanking:
                return "Loading group ranking..."

            case .noRanking:
                return "No ranking yet"

            case .rankingWillAppear:
                return "The ranking will appear when group data is available."

            case .myGroupBadge:
                return "My Group"

            case .alternativesTitle:
                return "Alternatives for Your Time"

            case .alternativesSubtitle:
                return "Did it? Check it off ✓"

            case .loadingAlternatives:
                return "Finding ideas for today..."

            case .alternativesFinished:
                return "You've completed today's suggestions"

            case .alternativesTomorrow:
                return "New ideas will be waiting for you tomorrow."

            case .groupActivityToday:
                return "What the Group Did Today"

            case .loadingGroupActivity:
                return "Loading group activity..."

            case .noAlternativeCompleted:
                return "No alternative has been completed today."

            case .beFirstInGroup:
                return "Be the first in your group to do something instead of using your phone."

            case .logout:
                return "Log Out"

            case .accountLoading:
                return "Loading your account..."

            case .accountUnavailable:
                return "Unable to load your account"

            case .tryLoginAgain:
                return "Try signing in again."

            case .language:
                return "Language"

            case .hebrew:
                return "Hebrew"

            case .english:
                return "English"

            case .arabic:
                return "Arabic"
            }

        // MARK: Arabic

        case .arabic:
            switch self {
            case .close:
                return "إغلاق"

            case .cancel:
                return "إلغاء"

            case .save:
                return "حفظ"

            case .done:
                return "تم"

            case .settings:
                return "الإعدادات"

            case .profile:
                return "الملف الشخصي"

            case .loading:
                return "جارٍ التحميل..."

            case .refresh:
                return "تحديث"

            case .error:
                return "خطأ"

            case .retry:
                return "حاول مرة أخرى"

            case .dashboard:
                return "لوحة التحكم"

            case .group:
                return "المجموعة"

            case .ranking:
                return "الترتيب"

            case .hello:
                return "مرحبًا"

            case .connectedToTimeUp:
                return "بياناتك متصلة بـ TimeUp"

            case .myGroup:
                return "مجموعتي"

            case .groupCode:
                return "رمز المجموعة"

            case .myToday:
                return "يومي"

            case .usage:
                return "الاستخدام"

            case .target:
                return "الهدف"

            case .learningDay:
                return "يوم التعلّم"

            case .achievedTarget:
                return "حققت الهدف"

            case .targetNotAchieved:
                return "لم يتحقق الهدف"

            case .dayInProgress:
                return "اليوم ما زال مستمرًا"

            case .groupStreak:
                return "سلسلة نجاح المجموعة"

            case .days:
                return "أيام"

            case .groupStatusToday:
                return "حالة المجموعة اليوم"

            case .completed:
                return "أكملوا"

            case .average:
                return "المتوسط"

            case .groupAchievedTarget:
                return "حققت المجموعة هدف اليوم"

            case .groupStillInProgress:
                return "لم تكمل المجموعة هدف اليوم بعد"

            case .groupResultPending:
                return "لم يتم تحديد نتيجة المجموعة لليوم بعد."

            case .members:
                return "الأعضاء"

            case .loadingGroup:
                return "جارٍ تحميل بيانات المجموعة..."

            case .noMembers:
                return "لا يوجد أعضاء للعرض"

            case .you:
                return "أنت"

            case .joined:
                return "انضم"

            case .groupRanking:
                return "ترتيب المجموعات"

            case .loadingRanking:
                return "جارٍ تحميل ترتيب المجموعات..."

            case .noRanking:
                return "لا يوجد ترتيب بعد"

            case .rankingWillAppear:
                return "سيظهر الترتيب عندما تتوفر بيانات المجموعات."

            case .myGroupBadge:
                return "مجموعتي"

            case .alternativesTitle:
                return "بدائل لاستخدام وقتكم"

            case .alternativesSubtitle:
                return "أنجزتم؟ ضعوا علامة ✓"

            case .loadingAlternatives:
                return "نختار لكم أفكارًا لليوم..."

            case .alternativesFinished:
                return "أنهيتم اقتراحات اليوم"

            case .alternativesTomorrow:
                return "ستنتظركم أفكار جديدة غدًا."

            case .groupActivityToday:
                return "ماذا فعلت المجموعة اليوم"

            case .loadingGroupActivity:
                return "جارٍ تحميل نشاط المجموعة..."

            case .noAlternativeCompleted:
                return "لم يتم إنجاز أي بديل اليوم بعد."

            case .beFirstInGroup:
                return "كونوا أول من يفعل شيئًا بدلًا من استخدام الهاتف."

            case .logout:
                return "تسجيل الخروج"

            case .accountLoading:
                return "جارٍ تحميل حسابك..."

            case .accountUnavailable:
                return "تعذر تحميل الحساب"

            case .tryLoginAgain:
                return "حاول تسجيل الدخول مرة أخرى."

            case .language:
                return "اللغة"

            case .hebrew:
                return "العبرية"

            case .english:
                return "الإنجليزية"

            case .arabic:
                return "العربية"
            }
        }
    }
}

// MARK: - Convenience View

struct TimeUpLocalizedText: View {

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    let key: TimeUpText

    init(_ key: TimeUpText) {
        self.key = key
    }

    var body: some View {
        Text(localization.text(key))
    }
}

// MARK: - View Localization Environment

private struct TimeUpLocalizationModifier: ViewModifier {

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    func body(content: Content) -> some View {
        content
            .environment(
                \.locale,
                localization.language.locale
            )
            .environment(
                \.layoutDirection,
                localization.language.layoutDirection
            )
    }
}

extension View {

    func timeUpLocalization() -> some View {
        modifier(TimeUpLocalizationModifier())
    }
}