import Foundation
import SwiftData

@Model
class DoublesMatch {
    @Attribute(.unique) var id: UUID
    @Relationship var session: Session
    @Relationship var redPlayer1: Player
    @Relationship var redPlayer2: Player
    @Relationship var blackPlayer1: Player
    @Relationship var blackPlayer2: Player

    var waveNumber: Int
    var redTeamScoreFirstSet: Int
    var blackTeamScoreFirstSet: Int
    var redTeamScoreSecondSet: Int
    var blackTeamScoreSecondSet: Int
    var isComplete: Bool
    
    init(
        id: UUID = UUID(),
        session: Session,
        waveNumber: Int,
        redPlayer1: Player,
        redPlayer2: Player,
        blackPlayer1: Player,
        blackPlayer2: Player,
        redTeamScoreFirstSet: Int = 0,
        blackTeamScoreFirstSet: Int = 0,
        redTeamScoreSecondSet: Int = 0,
        blackTeamScoreSecondSet: Int = 0,
        isComplete: Bool = false
    ) {
        self.id = id
        self.session = session
        self.waveNumber = waveNumber
        self.redPlayer1 = redPlayer1
        self.redPlayer2 = redPlayer2
        self.blackPlayer1 = blackPlayer1
        self.blackPlayer2 = blackPlayer2
        self.redTeamScoreFirstSet = redTeamScoreFirstSet
        self.blackTeamScoreFirstSet = blackTeamScoreFirstSet
        self.redTeamScoreSecondSet = redTeamScoreSecondSet
        self.blackTeamScoreSecondSet = blackTeamScoreSecondSet
        self.isComplete = isComplete
    }
}

