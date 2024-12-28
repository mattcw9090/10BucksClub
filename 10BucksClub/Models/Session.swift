import Foundation
import SwiftData

@Model
class Session {
    @Attribute(.unique) var id: UUID
    var sessionNumber: Int
    @Relationship var season: Season

    init(id: UUID = UUID(), number: Int, season: Season) {
        self.id = id
        self.sessionNumber = number
        self.season = season
    }
}
