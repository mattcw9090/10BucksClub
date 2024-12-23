import Foundation
import SwiftData

enum Team: String, Codable {
    case Red
    case Black
}

@Model
class SessionParticipants {
    @Relationship var session: Session
    @Relationship var player: Player
    var team: Team
    
    init(session: Session, player: Player, team: Team) {
        self.session = session
        self.player = player
        self.team = team
    }
}
