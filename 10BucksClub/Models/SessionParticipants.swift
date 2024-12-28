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
    
    var teamRawValue: String
    var team: Team {
        get { Team(rawValue: teamRawValue) ?? .Red }
        set { teamRawValue = newValue.rawValue }
    }

    init(session: Session, player: Player, team: Team) {
        self.session = session
        self.player = player
        self.teamRawValue = team.rawValue

        // Build a composite key like "2-5-UUID" so each (Session, Player) is unique.
        self.compositeKey = "\(session.uniqueIdentifier)-\(player.id)"
    }
}
