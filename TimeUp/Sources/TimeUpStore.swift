import Foundation
import Combine

enum TimeUpMemberRole: String, Codable {
    case admin
    case member
}

struct TimeUpMember: Identifiable, Codable {
    let id: UUID
    let groupID: UUID
    var displayName: String
    let role: TimeUpMemberRole
    let joinedAt: Date

    init(
        id: UUID = UUID(),
        groupID: UUID,
        displayName: String,
        role: TimeUpMemberRole = .member,
        joinedAt: Date = Date()
    ) {
        self.id = id
        self.groupID = groupID
        self.displayName = displayName
        self.role = role
        self.joinedAt = joinedAt
    }
}

final class TimeUpStore: ObservableObject {
    static let shared = TimeUpStore()

    @Published private(set) var groups: [TimeUpGroup] = []
    @Published private(set) var members: [TimeUpMember] = []

    private let groupsKey = "timeup.groups.v1"
    private let membersKey = "timeup.members.v1"
    private let currentMemberKey = "timeup.currentMemberID.v1"
    private let defaults = UserDefaults.standard

    private init() {
        load()
    }

    func addGroup(_ group: TimeUpGroup) {
        groups.append(group)
        save()
    }

    func updateGroup(_ group: TimeUpGroup) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index] = group
        save()
    }

    func group(forCode code: String) -> TimeUpGroup? {
        groups.first { $0.code == code }
    }

    func addMember(_ member: TimeUpMember) {
        guard !members.contains(where: { $0.id == member.id }) else { return }
        members.append(member)
        save()
    }

    func members(in groupID: UUID) -> [TimeUpMember] {
        members.filter { $0.groupID == groupID }
    }

    func member(id: UUID) -> TimeUpMember? {
        members.first { $0.id == id }
    }

    var currentMember: TimeUpMember? {
        guard let idString = defaults.string(forKey: currentMemberKey),
              let id = UUID(uuidString: idString) else {
            return nil
        }
        return member(id: id)
    }

    func setCurrentMember(_ member: TimeUpMember) {
        defaults.set(member.id.uuidString, forKey: currentMemberKey)
    }

    func hasMember(named name: String, in groupID: UUID) -> Bool {
        members.contains {
            $0.groupID == groupID &&
            $0.displayName.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    private func load() {
        if let data = defaults.data(forKey: groupsKey),
           let decoded = try? JSONDecoder().decode([TimeUpGroup].self, from: data) {
            groups = decoded
        }

        if let data = defaults.data(forKey: membersKey),
           let decoded = try? JSONDecoder().decode([TimeUpMember].self, from: data) {
            members = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(groups) {
            defaults.set(data, forKey: groupsKey)
        }

        if let data = try? JSONEncoder().encode(members) {
            defaults.set(data, forKey: membersKey)
        }
    }
}
