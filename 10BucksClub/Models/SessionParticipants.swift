import Foundation
import SwiftData

enum Team: String, Codable {
    case Red
    case Black
}

@Model
class SessionParticipants {
    @Attribute(.unique)
    var compositeKey: String
    
    @Relationship
    var session: Session
    
    @Relationship
    var player: Player
    
    var teamRawValue: String?
    var team: Team? {
        get {
            if let rawValue = teamRawValue {
                return Team(rawValue: rawValue)
            }
            return nil // Unassigned team
        }
        set {
            teamRawValue = newValue?.rawValue
        }
    }

    init(session: Session, player: Player, team: Team? = nil) {
        self.session = session
        self.player = player
        self.teamRawValue = team?.rawValue
        self.compositeKey = "\(session.uniqueIdentifier)-\(player.id)"
    }
}
