import Foundation
import SwiftData

@Model
class Player {
    @Attribute(.unique)
    var id: UUID

    var name: String
    var statusRawValue: String
    var waitlistPosition: Int?

    init(
        id: UUID = UUID(),
        name: String,
        status: PlayerStatus = .notInSession,
        waitlistPosition: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.statusRawValue = status.rawValue
        self.waitlistPosition = waitlistPosition
    }

    var status: PlayerStatus {
        get { PlayerStatus(rawValue: statusRawValue) ?? .notInSession }
        set { statusRawValue = newValue.rawValue }
    }

    enum PlayerStatus: String, Codable, CaseIterable {
        case playing = "Currently Playing"
        case onWaitlist = "On the Waitlist"
        case notInSession = "Not in Session"
    }
}
