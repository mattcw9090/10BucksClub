import Foundation
import SwiftData

@Model
class Session {
    var sessionNumber: Int
    var seasonNumber: Int

    @Attribute(.unique)
    var uniqueIdentifier: String

    @Relationship
    var season: Season
    
    @Relationship
    var participants: [SessionParticipants] = []

    init(sessionNumber: Int, season: Season) {
        self.sessionNumber = sessionNumber
        self.seasonNumber = season.seasonNumber
        self.uniqueIdentifier = "\(season.seasonNumber)-\(sessionNumber)"
        self.season = season
    }
}
