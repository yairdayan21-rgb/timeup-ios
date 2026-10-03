import Foundation
import Combine

enum TimeUpMemberRole: String, Codable {
    case admin
    case member
}

enum TimeUpAuthProvider: String, Codable {
    case apple
    case google
}

// MARK: - Chat Message

struct TimeUpChatMessage: Identifiable, Codable {

    let id: UUID
    let groupID: UUID
    let senderID: UUID
    let senderName: String
    let text: String
    let sentAt: Date

    var readByMemberIDs: [UUID]

    init(
        id: UUID = UUID(),
        groupID: UUID,
        senderID: UUID,
        senderName: String,
        text: String,
        sentAt: Date = Date(),
        readByMemberIDs: [UUID] = []
    ) {
        self.id = id
        self.groupID = groupID
        self.senderID = senderID
        self.senderName = senderName
        self.text = text
        self.sentAt = sentAt
        self.readByMemberIDs = readByMemberIDs
    }
}

struct TimeUpMember: Identifiable, Codable {

    let id: UUID
    let groupID: UUID
    var displayName: String
    let role: TimeUpMemberRole
    let joinedAt: Date

    var dailyTargetMinutes: Int?

    // זהות חיצונית של המשתמש.
    var authProvider: TimeUpAuthProvider?
    var externalUserID: String?

    init(
        id: UUID = UUID(),
        groupID: UUID,
        displayName: String,
        role: TimeUpMemberRole = .member,
        joinedAt: Date = Date(),
        dailyTargetMinutes: Int? = nil,
        authProvider: TimeUpAuthProvider? = nil,
        externalUserID: String? = nil
    ) {

        self.id = id
        self.groupID = groupID
        self.displayName = displayName
        self.role = role
        self.joinedAt = joinedAt
        self.dailyTargetMinutes = dailyTargetMinutes
        self.authProvider = authProvider
        self.externalUserID = externalUserID
    }
}

final class TimeUpStore: ObservableObject {

    static let shared = TimeUpStore()

    @Published private(set) var groups: [TimeUpGroup] = []

    @Published private(set) var members: [TimeUpMember] = []

    @Published private(set) var dailyProgress:
        [TimeUpDailyProgress] = []

    @Published private(set) var chatMessages:
        [TimeUpChatMessage] = []

    @Published private(set) var currentMember:
        TimeUpMember?

    // MARK: - App Lock

    // Face ID כבוי כברירת מחדל.
    @Published private(set) var isAppLockEnabled:
        Bool = false

    private let groupsKey =
        "timeup.groups.v1"

    private let membersKey =
        "timeup.members.v1"

    private let progressKey =
        "timeup.dailyProgress.v1"

    private let chatMessagesKey =
        "timeup.chatMessages.v1"

    private let currentMemberKey =
        "timeup.currentMemberID.v1"

    private let appLockEnabledKey =
        "timeup.appLockEnabled.v1"

    private let defaults =
        UserDefaults.standard

    private let calendar =
        Calendar.current

    private init() {

        load()

        restoreCurrentMember()

        restoreAppLockPreference()
    }

    // MARK: - Groups

    func addGroup(
        _ group: TimeUpGroup
    ) {

        groups.append(group)

        save()
    }

    func updateGroup(
        _ group: TimeUpGroup
    ) {

        guard
            let index =
                groups.firstIndex(
                    where: {
                        $0.id == group.id
                    }
                )
        else {
            return
        }

        groups[index] = group

        save()
    }

    func group(
        forCode code: String
    ) -> TimeUpGroup? {

        groups.first {
            $0.code == code
        }
    }

    // MARK: - Members

    func addMember(
        _ member: TimeUpMember
    ) {

        guard
            !members.contains(
                where: {
                    $0.id == member.id
                }
            )
        else {
            return
        }

        members.append(member)

        save()
    }

    func updateMember(
        _ member: TimeUpMember
    ) {

        guard
            let index =
                members.firstIndex(
                    where: {
                        $0.id == member.id
                    }
                )
        else {
            return
        }

        members[index] = member

        if currentMember?.id ==
            member.id
        {

            currentMember = member
        }

        save()
    }

    func setDailyTarget(
        _ targetMinutes: Int?,
        for memberID: UUID
    ) {

        guard
            let index =
                members.firstIndex(
                    where: {
                        $0.id == memberID
                    }
                )
        else {
            return
        }

        if let targetMinutes {

            members[index]
                .dailyTargetMinutes =
                    max(
                        0,
                        targetMinutes
                    )

        } else {

            members[index]
                .dailyTargetMinutes = nil
        }

        if currentMember?.id ==
            memberID
        {

            currentMember =
                members[index]
        }

        save()
    }

    func members(
        in groupID: UUID
    ) -> [TimeUpMember] {

        members.filter {
            $0.groupID == groupID
        }
    }

    func member(
        id: UUID
    ) -> TimeUpMember? {

        members.first {
            $0.id == id
        }
    }

    func member(
        authProvider:
            TimeUpAuthProvider,
        externalUserID: String
    ) -> TimeUpMember? {

        members.first {

            $0.authProvider ==
                authProvider &&

            $0.externalUserID ==
                externalUserID
        }
    }

    func connectAuthentication(
        provider:
            TimeUpAuthProvider,
        externalUserID: String,
        to memberID: UUID
    ) {

        guard
            let index =
                members.firstIndex(
                    where: {
                        $0.id == memberID
                    }
                )
        else {
            return
        }

        members[index]
            .authProvider =
                provider

        members[index]
            .externalUserID =
                externalUserID

        if currentMember?.id ==
            memberID
        {

            currentMember =
                members[index]
        }

        save()
    }

    func hasMember(
        named name: String,
        in groupID: UUID
    ) -> Bool {

        members.contains {

            $0.groupID ==
                groupID &&

            $0.displayName
                .caseInsensitiveCompare(
                    name
                ) == .orderedSame
        }
    }

    // MARK: - Session

    func setCurrentMember(
        _ member: TimeUpMember
    ) {

        if let storedMember =
            self.member(
                id: member.id
            )
        {

            currentMember =
                storedMember

        } else {

            currentMember =
                member
        }

        defaults.set(
            member.id.uuidString,
            forKey:
                currentMemberKey
        )
    }

    func clearCurrentMember() {

        currentMember = nil

        defaults.removeObject(
            forKey:
                currentMemberKey
        )
    }

    private func restoreCurrentMember() {

        guard
            let idString =
                defaults.string(
                    forKey:
                        currentMemberKey
                ),

            let id =
                UUID(
                    uuidString:
                        idString
                ),

            let storedMember =
                member(
                    id: id
                )
        else {

            currentMember = nil

            return
        }

        currentMember =
            storedMember
    }

    // MARK: - Face ID Preference

    func setAppLockEnabled(
        _ enabled: Bool
    ) {

        isAppLockEnabled =
            enabled

        defaults.set(
            enabled,
            forKey:
                appLockEnabledKey
        )
    }

    private func restoreAppLockPreference() {

        isAppLockEnabled =
            defaults.bool(
                forKey:
                    appLockEnabledKey
            )
    }

    // MARK: - Daily Progress

    func progress(
        for memberID: UUID
    ) -> [TimeUpDailyProgress] {

        dailyProgress
            .filter {

                $0.memberID ==
                    memberID
            }
            .sorted {

                $0.date <
                    $1.date
            }
    }

    func progress(
        for memberID: UUID,
        on date: Date
    ) -> TimeUpDailyProgress? {

        dailyProgress.first {

            $0.memberID ==
                memberID &&

            calendar.isDate(
                $0.date,
                inSameDayAs:
                    date
            )
        }
    }

    func todayProgress(
        for memberID: UUID
    ) -> TimeUpDailyProgress? {

        progress(
            for: memberID,
            on: Date()
        )
    }

    func previousProgress(
        for memberID: UUID,
        before date: Date = Date()
    ) -> TimeUpDailyProgress? {

        progress(
            for: memberID
        )
        .filter {

            $0.date <
                calendar.startOfDay(
                    for: date
                )
        }
        .last
    }

    func usageHistory(
        for memberID: UUID
    ) -> [Int] {

        progress(
            for: memberID
        )
        .map {
            $0.usageMinutes
        }
    }

    func currentStreak(
        for memberID: UUID
    ) -> Int {

        progress(
            for: memberID
        )
        .last?
        .streakAfterDay ?? 0
    }

    func saveDailyProgress(
        _ progress:
            TimeUpDailyProgress
    ) {

        if let index =
            dailyProgress.firstIndex(
                where: {

                    $0.memberID ==
                        progress.memberID &&

                    calendar.isDate(
                        $0.date,
                        inSameDayAs:
                            progress.date
                    )
                }
            )
        {

            dailyProgress[index] =
                progress

        } else {

            dailyProgress.append(
                progress
            )
        }

        dailyProgress.sort {

            $0.date <
                $1.date
        }

        save()
    }

    // MARK: - Complete Day

    @discardableResult
    func completeDay(
        for memberID: UUID,
        usageMinutes: Int,
        date: Date = Date(),
        isLearningDay: Bool = false
    ) -> TimeUpDailyProgress? {

        guard
            let member =
                member(
                    id: memberID
                ),

            let group =
                groups.first(
                    where: {

                        $0.id ==
                            member.groupID
                    }
                )
        else {

            return nil
        }

        let previousStreak =
            progress(
                for: memberID
            )
            .filter {

                $0.date <
                    calendar.startOfDay(
                        for: date
                    )
            }
            .last?
            .streakAfterDay ?? 0

        let progressEntry =
            TimeUpGoalEngine
                .makeDailyProgress(
                    memberID:
                        memberID,
                    date:
                        date,
                    usageMinutes:
                        max(
                            0,
                            usageMinutes
                        ),
                    targetMinutes:
                        member
                            .dailyTargetMinutes,
                    currentStreak:
                        previousStreak,
                    isLearningDay:
                        isLearningDay
                )

        saveDailyProgress(
            progressEntry
        )

        let historyBeforeToday =
            progress(
                for: memberID
            )
            .filter {

                $0.date <
                    calendar.startOfDay(
                        for: date
                    )
            }
            .map {
                $0.usageMinutes
            }

        let nextTarget =
            TimeUpGoalEngine
                .nextDayTargetMinutes(
                    for: group,
                    todayUsageMinutes:
                        progressEntry
                            .usageMinutes,
                    todayTargetMinutes:
                        progressEntry
                            .targetMinutes,
                    todayAchieved:
                        progressEntry
                            .achieved,
                    memberTargetMinutes:
                        member
                            .dailyTargetMinutes,
                    historicalUsageMinutes:
                        historyBeforeToday,
                    isLearningDay:
                        progressEntry
                            .isLearningDay
                )

        setDailyTarget(
            nextTarget,
            for: memberID
        )

        return progressEntry
    }

    // MARK: - Group Chat

    func messages(
        in groupID: UUID
    ) -> [TimeUpChatMessage] {

        chatMessages
            .filter {
                $0.groupID == groupID
            }
            .sorted {
                $0.sentAt < $1.sentAt
            }
    }

    func sendMessage(
        text: String,
        from memberID: UUID
    ) {

        let trimmedText =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedText.isEmpty else {
            return
        }

        guard
            let sender =
                member(
                    id: memberID
                )
        else {
            return
        }

        let message =
            TimeUpChatMessage(
                groupID:
                    sender.groupID,
                senderID:
                    sender.id,
                senderName:
                    sender.displayName,
                text:
                    trimmedText,
                sentAt:
                    Date(),
                readByMemberIDs: [
                    sender.id
                ]
            )

        chatMessages.append(
            message
        )

        chatMessages.sort {
            $0.sentAt < $1.sentAt
        }

        save()
    }

    func unreadMessageCount(
        in groupID: UUID,
        for memberID: UUID
    ) -> Int {

        chatMessages.filter {

            $0.groupID ==
                groupID &&

            $0.senderID !=
                memberID &&

            !$0.readByMemberIDs
                .contains(
                    memberID
                )
        }
        .count
    }

    func hasUnreadMessages(
        in groupID: UUID,
        for memberID: UUID
    ) -> Bool {

        unreadMessageCount(
            in: groupID,
            for: memberID
        ) > 0
    }

    func markGroupChatAsRead(
        groupID: UUID,
        by memberID: UUID
    ) {

        var changed = false

        for index in
            chatMessages.indices
        {

            guard
                chatMessages[index]
                    .groupID ==
                    groupID
            else {
                continue
            }

            guard
                chatMessages[index]
                    .senderID !=
                    memberID
            else {
                continue
            }

            guard
                !chatMessages[index]
                    .readByMemberIDs
                    .contains(
                        memberID
                    )
            else {
                continue
            }

            chatMessages[index]
                .readByMemberIDs
                .append(
                    memberID
                )

            changed = true
        }

        if changed {
            save()
        }
    }

    // MARK: - Persistence

    private func load() {

        if
            let data =
                defaults.data(
                    forKey:
                        groupsKey
                ),

            let decoded =
                try?
                    JSONDecoder()
                    .decode(
                        [TimeUpGroup].self,
                        from: data
                    )
        {

            groups = decoded
        }

        if
            let data =
                defaults.data(
                    forKey:
                        membersKey
                ),

            let decoded =
                try?
                    JSONDecoder()
                    .decode(
                        [TimeUpMember].self,
                        from: data
                    )
        {

            members = decoded
        }

        if
            let data =
                defaults.data(
                    forKey:
                        progressKey
                ),

            let decoded =
                try?
                    JSONDecoder()
                    .decode(
                        [TimeUpDailyProgress].self,
                        from: data
                    )
        {

            dailyProgress =
                decoded.sorted {

                    $0.date <
                        $1.date
                }
        }

        if
            let data =
                defaults.data(
                    forKey:
                        chatMessagesKey
                ),

            let decoded =
                try?
                    JSONDecoder()
                    .decode(
                        [TimeUpChatMessage].self,
                        from: data
                    )
        {

            chatMessages =
                decoded.sorted {

                    $0.sentAt <
                        $1.sentAt
                }
        }
    }

    private func save() {

        if let data =
            try?
                JSONEncoder()
                .encode(
                    groups
                )
        {

            defaults.set(
                data,
                forKey:
                    groupsKey
            )
        }

        if let data =
            try?
                JSONEncoder()
                .encode(
                    members
                )
        {

            defaults.set(
                data,
                forKey:
                    membersKey
            )
        }

        if let data =
            try?
                JSONEncoder()
                .encode(
                    dailyProgress
                )
        {

            defaults.set(
                data,
                forKey:
                    progressKey
            )
        }

        if let data =
            try?
                JSONEncoder()
                .encode(
                    chatMessages
                )
        {

            defaults.set(
                data,
                forKey:
                    chatMessagesKey
            )
        }
    }
}
