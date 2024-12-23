import Foundation
import SwiftData

@Model
class DoublesMatch {
    @Attribute(.unique) var id: UUID
    @Relationship var session: Session
    @Relationship var player1: Player
    @Relationship var player2: Player
    @Relationship var player3: Player
    @Relationship var player4: Player
    var waveNumber: Int
    var redTeamScoreFirstSet: Int
    var blackTeamScoreFirstSet: Int
    var redTeamScoreSecondSet: Int
    var blackTeamScoreSecondSet: Int
    
    init(
        id: UUID = UUID(),
        session: Session,
        waveNumber: Int,
        player1: Player,
        player2: Player,
        player3: Player,
        player4: Player,
        redTeamScoreFirstSet: Int = 0,
        blackTeamScoreFirstSet: Int = 0,
        redTeamScoreSecondSet: Int = 0,
        blackTeamScoreSecondSet: Int = 0
    ) {
        self.id = id
        self.session = session
        self.waveNumber = waveNumber
        self.player1 = player1
        self.player2 = player2
        self.player3 = player3
        self.player4 = player4
        self.redTeamScoreFirstSet = redTeamScoreFirstSet
        self.blackTeamScoreFirstSet = blackTeamScoreFirstSet
        self.redTeamScoreSecondSet = redTeamScoreSecondSet
        self.blackTeamScoreSecondSet = blackTeamScoreSecondSet
    }
}
