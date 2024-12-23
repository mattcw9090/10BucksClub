import Foundation
import SwiftData

@Model
class Session {
    @Attribute(.unique) var id: UUID
    var number: Int
    @Relationship var season: Season
    
    init(id: UUID = UUID(), number: Int, season: Season) {
        self.id = id
        self.number = number
        self.season = season
    }
}
